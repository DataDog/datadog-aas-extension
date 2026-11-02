using System.Xml;

/// <summary>Fault injection. Top-level types, because the engine resolves transforms by namespace and name.</summary>
namespace Datadog.AzureAppServices.DotNet.Xdt.Tests.Faults;


public class Throws : SetEnvironmentVariables
{
    protected override void BeforeCommit(XmlElement newRuntime) =>
        throw new InvalidOperationException("injected failure");
}

public class ThrowsAfterPartlyEditingTheCopy : SetEnvironmentVariables
{
    protected override void BeforeCommit(XmlElement newRuntime)
    {
        newRuntime.RemoveAll();
        throw new OutOfMemoryException("injected failure");
    }
}

