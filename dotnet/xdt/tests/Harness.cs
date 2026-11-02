using System.Text.RegularExpressions;
using System.Xml;
using Microsoft.Web.XmlTransform;

namespace Datadog.AzureAppServices.DotNet.Xdt.Tests;

/// <summary>Applies an xdt to a config with Microsoft.Web.XmlTransform, the way the platform does.</summary>
public sealed class Run
{
    public bool Ok;
    public List<string> Errors = new();
    public List<string> Warnings = new();
    public List<string> Messages = new();
    public XmlDocument Document;
    public string Text;

    public static Run Apply(string config, string xdt)
    {
        var doc = new XmlTransformableDocument { PreserveWhitespace = true };
        doc.LoadXml(config);
        var run = new Run();
        var logger = new Logger(run);
        using (var transform = new XmlTransformation(xdt, isTransformAFile: false, logger))
        {
            run.Ok = transform.Apply(doc);
        }

        run.Document = doc;
        run.Text = doc.OuterXml;
        return run;
    }

    private sealed class Logger : IXmlTransformationLogger
    {
        private readonly Run _run;
        public Logger(Run run) => _run = run;
        private static string F(string m, object[] a) => a == null || a.Length == 0 ? m : string.Format(m, a);
        public void LogMessage(string message, params object[] messageArgs) => _run.Messages.Add(F(message, messageArgs));
        public void LogMessage(MessageType type, string message, params object[] messageArgs) => _run.Messages.Add(F(message, messageArgs));
        public void LogWarning(string message, params object[] messageArgs) => _run.Warnings.Add(F(message, messageArgs));
        public void LogWarning(string file, string message, params object[] messageArgs) => _run.Warnings.Add(F(message, messageArgs));
        public void LogWarning(string file, int lineNumber, int linePosition, string message, params object[] messageArgs) => _run.Warnings.Add(F(message, messageArgs));
        public void LogError(string message, params object[] messageArgs) => _run.Errors.Add(F(message, messageArgs));
        public void LogError(string file, string message, params object[] messageArgs) => _run.Errors.Add(F(message, messageArgs));
        public void LogError(string file, int lineNumber, int linePosition, string message, params object[] messageArgs) => _run.Errors.Add(F(message, messageArgs));
        public void LogErrorFromException(Exception ex) => _run.Errors.Add(ex.Message);
        public void LogErrorFromException(Exception ex, string file) => _run.Errors.Add(ex.Message);
        public void LogErrorFromException(Exception ex, string file, int lineNumber, int linePosition) => _run.Errors.Add(ex.Message);
        public void StartSection(string message, params object[] messageArgs) { }
        public void StartSection(MessageType type, string message, params object[] messageArgs) { }
        public void EndSection(string message, params object[] messageArgs) { }
        public void EndSection(MessageType type, string message, params object[] messageArgs) { }
    }
}

public static class Files
{
    /// <summary>The repository root: the first parent of the test output that has dotnet/content.</summary>
    public static string Repo
    {
        get
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null && !File.Exists(Path.Combine(dir.FullName, "dotnet", "content", "applicationHost.xdt")))
            {
                dir = dir.Parent;
            }

            return dir?.FullName ?? throw new InvalidOperationException("repository root not found");
        }
    }

    public static string Dir => Path.Combine(Repo, "dotnet", "xdt", "tests", "inputs");
    public static string Read(string name) => File.ReadAllText(Path.Combine(Dir, name));

    /// <summary>An installed .NET applicationHost.xdt (v3_56_000, values filled in by install.ps1, pipe GUIDs replaced).</summary>
    public static string Today => Read("installed.applicationHost.xdt");

    /// <summary>The custom file generated from today's file, importing the transform compiled into this test assembly.</summary>
    public static string Custom => CustomWith(typeof(SetEnvironmentVariables));

    public static string CustomWith(Type transformType) =>
        Read("custom-from-installed.xdt")
            .Replace("path=\"TEST_IMPORT\"", $"assembly=\"{transformType.Assembly.GetName().Name}\"")
            .Replace("namespace=\"Datadog.AzureAppServices.DotNet.Xdt\"", $"namespace=\"{transformType.Namespace}\"")
            .Replace("xdt:Transform=\"SetEnvironmentVariables\"", $"xdt:Transform=\"{transformType.Name}\"");
}

/// <summary>What the worker would see: the root system.webServer/runtime/environmentVariables adds.</summary>
public static class Env
{
    public static List<(string Name, string Value)> Vars(XmlDocument doc)
    {
        var result = new List<(string, string)>();
        foreach (XmlElement add in doc.SelectNodes("/configuration/system.webServer/runtime/environmentVariables/add"))
        {
            result.Add((add.GetAttribute("name"), add.GetAttribute("value")));
        }

        return result;
    }

    /// <summary>IIS sets variables by name, so order doesn't matter, but duplicates do.</summary>
    public static List<string> Multiset(XmlDocument doc) =>
        Vars(doc).Select(v => v.Name + "=" + v.Value).OrderBy(s => s, StringComparer.Ordinal).ToList();

    /// <summary>
    /// The non-add children of the environment block (clear, remove, and so on) in order. Comments are
    /// ignored, because today's InsertIfMissing copies the xdt's comments into the config.
    /// </summary>
    public static List<string> OtherChildren(XmlDocument doc)
    {
        var vars = doc.SelectSingleNode("/configuration/system.webServer/runtime/environmentVariables");
        if (vars == null) return new();
        return vars.ChildNodes.OfType<XmlElement>().Where(e => e.LocalName != "add").Select(e => e.OuterXml).ToList();
    }

    /// <summary>Everything except the root runtime section, with whitespace and comments removed.</summary>
    public static string Rest(XmlDocument doc)
    {
        var copy = (XmlDocument)doc.Clone();
        var runtime = copy.SelectSingleNode("/configuration/system.webServer/runtime");
        runtime?.ParentNode.RemoveChild(runtime);
        foreach (XmlNode comment in copy.SelectNodes("//comment()").Cast<XmlNode>().ToList())
        {
            comment.ParentNode.RemoveChild(comment);
        }

        return Regex.Replace(copy.OuterXml, @">\s+<", "><");
    }
}
