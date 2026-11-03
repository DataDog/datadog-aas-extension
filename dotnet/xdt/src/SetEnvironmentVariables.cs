// One XDT operation that sets the Datadog .NET extension's IIS environment variables on the main site.
//
// App Service applies every site extension's applicationHost.xdt in one run as part of startup.
// This custom operation is faster than applying individual settings.
//
// Use it on <system.webServer xdt:Transform="SetEnvironmentVariables">, with these children:
//   <add name="X" value="v" />           replace every add named X with this one (today's RemoveAll + Insert)
//   <addIfMissing name="X" value="v" />  add only if no add named X exists (today's InsertIfMissing)
//   <remove name="X" />                  remove every add named X (today's RemoveAll alone)
//
// Safety rules:
//   1. It never throws and never logs an error. Problems are logged as warnings.
//   2. All or nothing. It checks every child first and builds the new <runtime> element on a copy.
//      The live document changes in one step at the end.
//   3. It only touches add elements with the names it was given. Everything else is kept as it is, in order.
//   4. It depends only on mscorlib, System.Xml, and Microsoft.Web.XmlTransform.
// This code runs inside the platform's config step for every extension. any error drops every config
// It is important for this code to be reliable.
using System;
using System.Collections.Generic;
using System.Xml;
using Microsoft.Web.XmlTransform;

namespace Datadog.AzureAppServices.DotNet.Xdt
{
    public class SetEnvironmentVariables : Transform
    {
        public const string Version = "0.2.0";
        private const string XdtNamespace = "http://schemas.microsoft.com/XML-Document-Transform";

        // A missing system.webServer is only a warning, like a RemoveAll that matches nothing.
        public SetEnvironmentVariables()
            : base(TransformFlags.None, MissingTargetMessage.Warning)
        {
        }

        protected override void Apply()
        {
            try
            {
                var webServer = TargetNode as XmlElement;
                if (webServer == null || webServer.OwnerDocument == null)
                {
                    Warn("the target is not an element in a document");
                    return;
                }

                string problem;
                var changes = ReadChanges(TransformNode, out problem);
                if (changes == null)
                {
                    Warn(problem);
                    return;
                }

                var oldRuntime = FirstChild(webServer, "runtime");
                var newRuntime = oldRuntime != null
                    ? (XmlElement)oldRuntime.CloneNode(deep: true)
                    : webServer.OwnerDocument.CreateElement("runtime", webServer.NamespaceURI);
                var counts = ApplyChanges(newRuntime, changes);

                BeforeCommit(newRuntime);

                // The only change to the live document.
                if (oldRuntime != null)
                {
                    webServer.ReplaceChild(newRuntime, oldRuntime);
                }
                else
                {
                    webServer.AppendChild(newRuntime);
                }

                Log.LogMessage(
                    "Datadog.Xdt {0}: set {1}, kept {2} existing, removed {3} (engine {4})",
                    Version, counts[0], counts[1], counts[2], typeof(Transform).Assembly.GetName().Version);
            }
            catch (Exception ex)
            {
                Warn(ex.GetType().Name + ": " + ex.Message);
            }
        }

        // Test seam: runs after the new runtime element is built and before the live document changes.
        protected virtual void BeforeCommit(XmlElement newRuntime)
        {
        }

        private void Warn(string problem)
        {
            try
            {
                Log.LogWarning("Datadog.Xdt {0} left the config unchanged: {1}", Version, problem);
            }
            catch
            {
                // Never let logging fail the run.
            }
        }

        internal enum Kind { Set, SetIfMissing, Remove }

        internal sealed class Change
        {
            public Kind Kind;
            public string Name;
            public string Value;
        }

        // Returns null, with the reason, if any child is not something this transform understands.
        internal static List<Change> ReadChanges(XmlNode transformNode, out string problem)
        {
            problem = null;
            var changes = new List<Change>();
            var seen = new HashSet<string>(StringComparer.Ordinal);
            foreach (XmlNode node in transformNode.ChildNodes)
            {
                if (node.NodeType == XmlNodeType.Comment || node.NodeType == XmlNodeType.Whitespace
                    || node.NodeType == XmlNodeType.SignificantWhitespace)
                {
                    continue;
                }

                var element = node as XmlElement;
                if (element == null)
                {
                    problem = "unexpected " + node.NodeType + " child";
                    return null;
                }

                Kind kind;
                switch (element.LocalName)
                {
                    case "add": kind = Kind.Set; break;
                    case "addIfMissing": kind = Kind.SetIfMissing; break;
                    case "remove": kind = Kind.Remove; break;
                    default:
                        problem = "unknown child <" + element.Name + ">";
                        return null;
                }

                string name = null, value = null;
                foreach (XmlAttribute attribute in element.Attributes)
                {
                    if (attribute.NamespaceURI == XdtNamespace || attribute.Prefix == "xmlns" || attribute.Name == "xmlns")
                    {
                        continue;
                    }

                    if (attribute.Name == "name") name = attribute.Value;
                    else if (attribute.Name == "value" && kind != Kind.Remove) value = attribute.Value;
                    else
                    {
                        problem = "unexpected attribute " + attribute.Name + " on <" + element.Name + ">";
                        return null;
                    }
                }

                if (string.IsNullOrEmpty(name))
                {
                    problem = "<" + element.Name + "> without a name";
                    return null;
                }

                if (kind != Kind.Remove && value == null)
                {
                    problem = "<" + element.Name + " name=\"" + name + "\"> without a value";
                    return null;
                }

                if (!seen.Add(name))
                {
                    problem = "the name " + name + " appears more than once";
                    return null;
                }

                changes.Add(new Change { Kind = kind, Name = name, Value = value });
            }

            if (changes.Count == 0)
            {
                problem = "no variables to set";
                return null;
            }

            return changes;
        }

        // Applies the changes to a detached runtime element. Returns { set, kept, removed }.
        internal static int[] ApplyChanges(XmlElement runtime, List<Change> changes)
        {
            var doc = runtime.OwnerDocument;
            var vars = FirstChild(runtime, "environmentVariables");
            if (vars == null)
            {
                vars = doc.CreateElement("environmentVariables", runtime.NamespaceURI);
                runtime.AppendChild(vars);
            }

            int set = 0, kept = 0, removed = 0;
            foreach (var change in changes)
            {
                var existing = Adds(vars, change.Name);
                if (change.Kind == Kind.SetIfMissing && existing.Count > 0)
                {
                    kept++;
                    continue;
                }

                if (change.Kind != Kind.SetIfMissing)
                {
                    foreach (var node in existing)
                    {
                        vars.RemoveChild(node);
                        removed++;
                    }
                }

                if (change.Kind == Kind.Remove)
                {
                    continue;
                }

                var add = doc.CreateElement("add", vars.NamespaceURI);
                add.SetAttribute("name", change.Name);
                add.SetAttribute("value", change.Value);
                vars.AppendChild(add);
                set++;
            }

            return new[] { set, kept, removed };
        }

        private static XmlElement FirstChild(XmlElement parent, string localName)
        {
            foreach (XmlNode node in parent.ChildNodes)
            {
                var element = node as XmlElement;
                if (element != null && element.LocalName == localName)
                {
                    return element;
                }
            }

            return null;
        }

        private static List<XmlElement> Adds(XmlElement vars, string name)
        {
            var result = new List<XmlElement>();
            foreach (XmlNode node in vars.ChildNodes)
            {
                var element = node as XmlElement;
                if (element != null && element.LocalName == "add" && element.GetAttribute("name") == name)
                {
                    result.Add(element);
                }
            }

            return result;
        }
    }
}
