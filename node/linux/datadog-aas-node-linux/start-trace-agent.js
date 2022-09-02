const { spawn } = require('child_process');

const trace_agent_path = process.env["DD_TRACE_AGENT_PATH"]
// const trace_agent_args = process.env["DD_TRACE_AGENT_ARGS"].split(" ");
const trace_agent_child = spawn(trace_agent_path, {
    detached: true,
    stdio: ['ignore', 'ignore', 'ignore']
});

trace_agent_child.unref();