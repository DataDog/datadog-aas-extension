using Xunit;

namespace Datadog.AzureAppServices.DotNet.Xdt.Tests;

/// <summary>
/// Risk: the one-operation transform gives the worker different variables than today's file.
/// Today's RemoveAll + Insert file is the reference for every input shape.
/// </summary>
public class EquivalenceTests
{
    [Theory]
    [MemberData(nameof(Corpus.Shapes), MemberType = typeof(Corpus))]
    public void SameVariablesAsTodaysFile(string shape)
    {
        var input = Corpus.Build(shape);
        var today = Run.Apply(input, Files.Standard);
        var custom = Run.Apply(input, Files.Custom);

        Assert.True(today.Ok, "today's file failed on this input, so the input is wrong");
        Assert.True(custom.Ok);
        Assert.Empty(custom.Errors);
        Assert.Equal(Env.Multiset(today.Document), Env.Multiset(custom.Document));
        Assert.Equal(Env.OtherChildren(today.Document), Env.OtherChildren(custom.Document));
        Assert.Equal(Env.Rest(today.Document), Env.Rest(custom.Document));
    }

    /// <summary>Random environment blocks, mixing our names, other names, duplicates, and directives.</summary>
    [Fact]
    public void RandomInputsMatchTodaysFile()
    {
        var random = new Random(9057);
        var names = Corpus.OurNames.Concat(new[] { "OTHER_A", "OTHER_B", "CORECLR_PROFILER", "dd_trace_pipe_name", "DD_INSTRUMENTATION_INSTALL_TYPE" }).ToArray();
        for (var i = 0; i < 300; i++)
        {
            var input = Corpus.Edit(ws =>
            {
                var vars = (System.Xml.XmlElement)ws.SelectSingleNode("runtime/environmentVariables");
                var count = random.Next(0, 12);
                for (var j = 0; j < count; j++)
                {
                    var roll = random.Next(20);
                    if (roll == 0) vars.AppendChild(vars.OwnerDocument.CreateElement("clear", vars.NamespaceURI));
                    else if (roll == 1) vars.AppendChild(vars.OwnerDocument.CreateComment("c" + j));
                    else vars.AppendChild(Corpus.Add(vars, names[random.Next(names.Length)], "v" + random.Next(3)));
                }
            });

            var today = Run.Apply(input, Files.Standard);
            var custom = Run.Apply(input, Files.Custom);
            Assert.True(custom.Ok, $"case {i}");
            Assert.Empty(custom.Errors);
            Assert.Equal(Env.Multiset(today.Document), Env.Multiset(custom.Document));
            Assert.Equal(Env.OtherChildren(today.Document), Env.OtherChildren(custom.Document));
        }
    }
}
