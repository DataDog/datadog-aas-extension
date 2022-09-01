using System;
using System.Diagnostics;
internal class StartupHook
{
    public static void Initialize()
    {
        string? agentPath = Environment.GetEnvironmentVariable("DD_TRACE_AGENT_PATH");

        if (agentPath == null)
        {
            return;
        }

        Process.Start(agentPath);
    }
}
