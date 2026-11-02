using System.Xml;
using Xunit;

namespace Datadog.AzureAppServices.DotNet.Xdt.Tests;

/// <summary>
/// Risk: our code runs in the platform's config step, and an error there drops every extension's
/// config. Whatever goes wrong, the run must succeed (no error logged), and the config must be left
/// exactly as it was, so only Datadog's own settings are missing.
/// </summary>
public class SafetyTests
{
    private static void AssertLeftAlone(string input, Run run)
    {
        Assert.True(run.Ok, "errors: " + string.Join(" | ", run.Errors) + " warnings: " + string.Join(" | ", run.Warnings));
        Assert.Empty(run.Errors);
        Assert.Contains(run.Warnings, w => w.Contains("left the config unchanged"));
        var before = new XmlDocument { PreserveWhitespace = true };
        before.LoadXml(input);
        Assert.Equal(before.OuterXml, run.Text);
    }

    [Theory]
    [MemberData(nameof(Corpus.Shapes), MemberType = typeof(Corpus))]
    public void AnExceptionLeavesTheConfigUnchanged(string shape)
    {
        var input = Corpus.Build(shape);
        AssertLeftAlone(input, Run.Apply(input, Files.CustomWith(typeof(Faults.Throws))));
        AssertLeftAlone(input, Run.Apply(input, Files.CustomWith(typeof(Faults.ThrowsAfterPartlyEditingTheCopy))));
    }

    [Fact]
    public void AnExceptionKeepsOtherExtensionsSettings()
    {
        // Another extension (sorted before Datadog) has already added its variable in the same run.
        var input = Corpus.Vars(("DD_PROBE_AA", "1"));
        var run = Run.Apply(input, Files.CustomWith(typeof(Faults.Throws)));
        Assert.Contains(("DD_PROBE_AA", "1"), Env.Vars(run.Document));
    }

    public static IEnumerable<object[]> BadChildren() => new[]
    {
        new object[] { "<add value=\"1\" />" },
        new object[] { "<add name=\"\" value=\"1\" />" },
        new object[] { "<add name=\"NO_VALUE\" />" },
        new object[] { "<set name=\"X\" value=\"1\" />" },
        new object[] { "<add name=\"X\" value=\"1\" extra=\"y\" />" },
        new object[] { "<add name=\"DD_AZURE_APP_SERVICES\" value=\"2\" />" },
        new object[] { "text" },
    };

    [Theory]
    [MemberData(nameof(BadChildren))]
    public void AnUnexpectedChildLeavesTheConfigUnchanged(string child)
    {
        var xdt = Files.Custom.Replace("</system.webServer>", "    " + child + "\r\n  </system.webServer>");
        var input = Corpus.Build("our names twice with old values, plus an unrelated variable");
        AssertLeftAlone(input, Run.Apply(input, xdt));
    }

    [Fact]
    public void NoVariablesLeavesTheConfigUnchanged()
    {
        var xdt = System.Text.RegularExpressions.Regex.Replace(Files.Custom, "<(add|addIfMissing|remove) [^>]*/>", "");
        AssertLeftAlone(Corpus.Base, Run.Apply(Corpus.Base, xdt));
    }

    [Fact]
    public void AConfigWithoutSystemWebServerIsOnlyAWarning()
    {
        var input = Corpus.Base.Replace("<system.webServer>", "<system.webServerX>").Replace("</system.webServer>", "</system.webServerX>");
        var run = Run.Apply(input, Files.Custom);
        Assert.True(run.Ok);
        Assert.Empty(run.Errors);
    }

    [Fact]
    public void ItLogsWhatItDidAndTheEngineVersion()
    {
        var run = Run.Apply(Corpus.Base, Files.Custom);
        var line = Assert.Single(run.Messages, m => m.StartsWith("Datadog.Xdt "));
        Assert.Matches(@"Datadog\.Xdt \S+: set \d+, kept \d+ existing, removed \d+ \(engine \d+\.\d+", line);
    }

    [Fact]
    public void OnlyTheRootEnvironmentBlockChanges()
    {
        // A site-level system.webServer under <location> must not be touched.
        var input = Corpus.Base.Replace("</configuration>",
            "<location path=\"x\"><system.webServer><runtime><environmentVariables><add name=\"DD_AZURE_APP_SERVICES\" value=\"site\" /></environmentVariables></runtime></system.webServer></location></configuration>");
        var run = Run.Apply(input, Files.Custom);
        Assert.Equal("site", ((XmlElement)run.Document.SelectSingleNode("//location[@path='x']//add")).GetAttribute("value"));
    }
}

