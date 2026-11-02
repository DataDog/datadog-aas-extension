using System.Text.RegularExpressions;
using System.Xml;

namespace Datadog.AzureAppServices.DotNet.Xdt.Tests;

/// <summary>
/// Input configs, built from an applicationhost.config downloaded from a test App Service, in the
/// shapes a customer's worker can have before Datadog's step runs.
/// </summary>
public static class Corpus
{
    public static string Base => Files.Read("platform.applicationhost.config");

    public static readonly string[] OurNames = Regex
        .Matches(Files.Today, "<add name=\"([^\"]+)\"")
        .Select(m => m.Groups[1].Value).Distinct().ToArray();

    public static IEnumerable<object[]> Shapes() => Builders.Keys.Select(k => new object[] { k });

    public static string Build(string shape) => Builders[shape]();

    private static readonly Dictionary<string, Func<string>> Builders = new()
    {
        ["empty environmentVariables"] = () => Base,
        ["no runtime section"] = () => Edit(ws => ws.RemoveChild(ws.SelectSingleNode("runtime"))),
        ["runtime without environmentVariables"] = () => Edit(ws =>
        {
            var rt = ws.SelectSingleNode("runtime");
            rt.RemoveChild(rt.SelectSingleNode("environmentVariables"));
        }),
        ["our names twice with old values, plus an unrelated variable"] = () => Vars(
            new[] { ("UNRELATED_VAR", "keep-me") }
                .Concat(OurNames.Select((n, i) => (n, "old-" + i)))
                .Concat(OurNames.Select((n, i) => (n, "older-" + i))).ToArray()),
        ["another vendor's profiler (Application Insights)"] = () => Vars(
            ("CORECLR_ENABLE_PROFILING", "1"),
            ("CORECLR_PROFILER", "{324F817A-7420-4E6D-B3C1-143FBED6D855}"),
            ("CORECLR_PROFILER_PATH_64", @"D:\Program Files (x86)\SiteExtensions\InstrumentationEngine\1.0.43\Instrumentation64\MicrosoftInstrumentationEngine_x64.dll"),
            ("COR_ENABLE_PROFILING", "1"),
            ("MicrosoftInstrumentationEngine_IsPreinstalled", "1"),
            ("APPINSIGHTS_PROFILERFEATURE_VERSION", "1.0.0")),
        ["customer Datadog settings"] = () => Vars(
            ("DD_INSTRUMENTATION_INSTALL_TYPE", "customer-set"),
            ("DD_TRACE_METRICS_ENABLED", "true"),
            ("DD_ENV", "prod")),
        ["clear and remove directives"] = () => Edit(ws =>
        {
            var vars = (XmlElement)ws.SelectSingleNode("runtime/environmentVariables");
            vars.AppendChild(Element(vars, "clear"));
            var remove = Element(vars, "remove");
            remove.SetAttribute("name", "SOMETHING");
            vars.AppendChild(remove);
            vars.AppendChild(Add(vars, "DD_AZURE_APP_SERVICES", "0"));
            vars.AppendChild(Add(vars, "AFTER_CLEAR", "1"));
        }),
        ["comments and whitespace"] = () => Edit(ws =>
        {
            var vars = (XmlElement)ws.SelectSingleNode("runtime/environmentVariables");
            vars.AppendChild(vars.OwnerDocument.CreateComment(" a comment "));
            vars.AppendChild(vars.OwnerDocument.CreateWhitespace("\r\n        "));
            vars.AppendChild(Add(vars, "DD_TRACE_PIPE_NAME", "old"));
            vars.AppendChild(vars.OwnerDocument.CreateComment(" another "));
        }),
        ["a lowercase copy of one of our names"] = () => Vars(("dd_azure_app_services", "1")),
        ["already applied once"] = () => Run.Apply(Base, Files.Today).Text,
    };

    public static string Vars(params (string Name, string Value)[] vars) => Edit(ws =>
    {
        var env = (XmlElement)ws.SelectSingleNode("runtime/environmentVariables");
        foreach (var (name, value) in vars) env.AppendChild(Add(env, name, value));
    });

    public static string Edit(Action<XmlElement> edit)
    {
        var doc = new XmlDocument { PreserveWhitespace = true };
        doc.LoadXml(Base);
        edit((XmlElement)doc.SelectSingleNode("/configuration/system.webServer"));
        return doc.OuterXml;
    }

    public static XmlElement Add(XmlElement parent, string name, string value)
    {
        var add = Element(parent, "add");
        add.SetAttribute("name", name);
        add.SetAttribute("value", value);
        return add;
    }

    private static XmlElement Element(XmlElement parent, string name) =>
        parent.OwnerDocument.CreateElement(name, parent.NamespaceURI);
}
