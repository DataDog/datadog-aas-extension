#!/usr/bin/env bash

export DD_TRACE_AGENT_PATH="/home/site/wwwroot/datadog-aas-node-linux/trace-agent"
export NODE_OPTIONS='--require="dd-trace/init" --require="/home/site/wwwroot/datadog-aas-node-linux/start-trace-agent.js"'
