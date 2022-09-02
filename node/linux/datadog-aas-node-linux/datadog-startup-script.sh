#!/usr/bin/env bash

export NODE_PATH="$NODE_PATH:/home/site/wwwroot/datadog-js/js-tracer/node_modules"
export DD_TRACE_AGENT_PATH="/home/site/wwwroot/datadog-js/trace-agent/trace-agent"
export NODE_OPTIONS='--require="dd-trace/init" --require="/home/site/wwwroot/start-trace-agent.js"'
