#!/usr/bin/env bash

export CORECLR_ENABLE_PROFILING=1
export CORECLR_PROFILER="{846F5F1C-F9AE-4B07-969E-05C26BC060D8}"
export CORECLR_PROFILER_PATH="/home/site/wwwroot/datadog/linux-x64/Datadog.Trace.ClrProfiler.Native.so"
export DD_DOTNET_TRACER_HOME="/home/site/wwwroot/datadog"
export DD_TRACE_AGENT_PATH="/home/site/wwwroot/datadog-aas-dotnet-linux/trace-agent"
export DOTNET_STARTUP_HOOKS="/home/site/wwwroot/datadog-aas-dotnet-linux/datadog-startup-hook.dll"
