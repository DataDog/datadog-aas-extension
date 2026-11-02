using System.Reflection.Metadata;
using System.Reflection.PortableExecutable;
using System.Text.RegularExpressions;
using System.Xml;
using Xunit;

namespace Datadog.AzureAppServices.DotNet.Xdt.Tests;

/// <summary>
/// Risks around how the transform is built and shipped: an extra dependency the platform can't
/// load, shipping our own copy of the engine, a relative import path, a generated file that drifts
/// from today's file, and install.ps1 edits that stop matching.
/// </summary>
public class PackagingTests
{
    private static string Repo => Files.Repo;
    private static string BuiltDll => Path.Combine(Repo, "dotnet", "xdt", "src", "bin", "Release", "net45", "Datadog.AzureAppServices.DotNet.Xdt.dll");
    private static string Template => File.ReadAllText(Path.Combine(Repo, "dotnet", "content", "applicationHost.custom.xdt"));
    private static string RepoXdt => File.ReadAllText(Path.Combine(Repo, "dotnet", "content", "applicationHost.xdt"));

    private static MetadataReader Metadata(out PEReader pe)
    {
        Assert.True(File.Exists(BuiltDll), "build first: dotnet build -c Release dotnet/xdt/src");
        pe = new PEReader(File.OpenRead(BuiltDll));
        return pe.GetMetadataReader();
    }

    [Fact]
    public void ReferencesOnlyTheFrameworkAndTheGacEngine()
    {
        var md = Metadata(out var pe);
        using (pe)
        {
            var refs = md.AssemblyReferences.Select(h => md.GetAssemblyReference(h))
                .Select(r => md.GetString(r.Name) + " " + r.Version).OrderBy(s => s).ToList();
            // Only .NET Framework 4 assemblies, which every instance has, and the engine from the GAC.
            var allowed = new[] { "Microsoft.Web.XmlTransform 1.4.0.0", "System.Core 4.0.0.0", "System.Xml 4.0.0.0", "mscorlib 4.0.0.0" };
            Assert.Empty(refs.Except(allowed));
        }
    }

    [Fact]
    public void TargetsNetFramework45()
    {
        var md = Metadata(out var pe);
        using (pe)
        {
            var values = md.CustomAttributes.Select(h => md.GetCustomAttribute(h))
                .Select(a => System.Text.Encoding.UTF8.GetString(md.GetBlobBytes(a.Value))).ToList();
            Assert.Contains(values, v => v.Contains(".NETFramework,Version=v4.5"));
        }
    }

    [Fact]
    public void DoesNotShipItsOwnCopyOfTheEngine()
    {
        // A second Microsoft.Web.XmlTransform next to ours could make our Transform a different type
        // from the engine's, and the import would fail.
        Assert.False(File.Exists(Path.Combine(Path.GetDirectoryName(BuiltDll), "Microsoft.Web.XmlTransform.dll")));
    }

    [Fact]
    public void TheShippedFileImportsByAnAbsoluteVersionedPath()
    {
        // A relative path fails on App Service with "Illegal characters in path" and drops every extension.
        var import = Regex.Match(Template, "<xdt:Import path=\"([^\"]+)\" namespace=\"([^\"]+)\" />");
        Assert.True(import.Success);
        Assert.Equal(@"%XDT_EXTENSIONPATH%\vFOLDERUNKNOWN\Datadog.AzureAppServices.DotNet.Xdt.dll", import.Groups[1].Value);
        Assert.Equal(typeof(SetEnvironmentVariables).Namespace, import.Groups[2].Value);
    }

    [Fact]
    public void TheShippedFileIsOneOperation()
    {
        var transforms = Regex.Matches(Template, "xdt:Transform=\"([^\"]+)\"").Select(m => m.Groups[1].Value).ToList();
        Assert.Equal(new[] { nameof(SetEnvironmentVariables) }, transforms);
        Assert.DoesNotContain("xdt:Locator", Template);
    }

    /// <summary>Independent of make-custom-xdt.py: derive the expected children from a RemoveAll + Insert file.</summary>
    private static List<string> Expected(string removeInsertXdt)
    {
        var doc = new XmlDocument();
        doc.LoadXml(removeInsertXdt);
        var ns = new XmlNamespaceManager(doc.NameTable);
        ns.AddNamespace("xdt", "http://schemas.microsoft.com/XML-Document-Transform");
        var adds = doc.SelectNodes("//environmentVariables/add", ns).Cast<XmlElement>().ToList();
        string T(XmlElement e) => e.GetAttribute("Transform", "http://schemas.microsoft.com/XML-Document-Transform");
        var inserted = adds.Where(a => T(a) == "Insert").Select(a => a.GetAttribute("name")).ToHashSet();
        return adds.Where(a => T(a) == "RemoveAll" && !inserted.Contains(a.GetAttribute("name"))).Select(a => $"remove {a.GetAttribute("name")}")
            .Concat(adds.Where(a => T(a) == "Insert").Select(a => $"add {a.GetAttribute("name")}={a.GetAttribute("value")}"))
            .Concat(adds.Where(a => T(a) == "InsertIfMissing").Select(a => $"addIfMissing {a.GetAttribute("name")}={a.GetAttribute("value")}"))
            .ToList();
    }

    private static List<string> Actual(string customXdt)
    {
        var doc = new XmlDocument();
        doc.LoadXml(customXdt);
        return doc.SelectSingleNode("/configuration/system.webServer").ChildNodes.OfType<XmlElement>()
            .Select(e => e.LocalName == "remove" ? $"remove {e.GetAttribute("name")}" : $"{e.LocalName} {e.GetAttribute("name")}={e.GetAttribute("value")}")
            .ToList();
    }

    [Fact]
    public void TheShippedFileMatchesTheRepositoryTemplate() => Assert.Equal(Expected(RepoXdt), Actual(Template));

    [Fact]
    public void TheTestFileMatchesTodaysInstalledFile() => Assert.Equal(Expected(Files.Today), Actual(Files.Read("custom-from-installed.xdt")));

    /// <summary>Applies every -replace 'pattern', 'replacement' in install.ps1's .NET Core branch.</summary>
    private static string CoreEdits(string xdt)
    {
        var script = File.ReadAllText(Path.Combine(Repo, "dotnet", "content", "install.ps1"));
        var core = script.Substring(script.IndexOf("if ($dotnetRuntime -eq \"Core\")", StringComparison.Ordinal));
        core = core.Substring(0, core.IndexOf("\n}", StringComparison.Ordinal));
        var edits = Regex.Matches(core, @"-replace '([^']+)', '([^']*)'");
        Assert.NotEmpty(edits);
        foreach (Match edit in edits)
        {
            xdt = Regex.Replace(xdt, edit.Groups[1].Value, edit.Groups[2].Value);
        }

        return xdt;
    }

    [Fact]
    public void InstallScriptTurnsOffNetFrameworkProfilingForNetCoreInBothFiles()
    {
        // install.ps1 removes COR_ENABLE_PROFILING for .NET Core apps by regex. The original pattern
        // only matched the RemoveAll + Insert form, so it would silently miss the one-step file.
        var custom = CoreEdits(Template);
        Assert.Contains("<remove name=\"COR_ENABLE_PROFILING\" />", custom);
        Assert.DoesNotContain("<add name=\"COR_ENABLE_PROFILING\"", custom);

        var classic = CoreEdits(RepoXdt);
        Assert.DoesNotMatch(@"<add name=""COR_ENABLE_PROFILING""[^>]*xdt:Transform=""Insert""", classic);
        Assert.Contains("name=\"COR_ENABLE_PROFILING\" xdt:Locator=\"Match(name)\" xdt:Transform=\"RemoveAll\"", classic);
    }

    [Fact]
    public void InstallScriptPlaceholdersStillAppear()
    {
        // build-packages.sh fills vFOLDERUNKNOWN and vUNKNOWN; install.ps1 fills the pipe GUIDs.
        foreach (var placeholder in new[] { "vFOLDERUNKNOWN", "vUNKNOWN", "uniqueTracePipeId", "uniqueStatsPipeId" })
        {
            Assert.Equal(Regex.Matches(RepoXdt, placeholder).Count > 0, Template.Contains(placeholder));
        }
    }

#if XDT_1_4
    [Fact]
    public void TheBuiltDllLoadsThroughAnAbsoluteImportPath()
    {
        var xdt = Files.Read("custom-from-installed.xdt").Replace("TEST_IMPORT", BuiltDll);
        var run = Run.Apply(Corpus.Base, xdt);
        Assert.True(run.Ok, string.Join("; ", run.Errors));
        Assert.Equal(Env.Multiset(Run.Apply(Corpus.Base, Files.Today).Document), Env.Multiset(run.Document));
    }
#endif
}
