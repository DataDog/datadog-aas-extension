#!/usr/bin/env bash

# requires UPDATE_AGENT=true and AGENT_VERSION=(e.g. datadog-agent_7.38.2-1_amd64.deb)
# checks for the latest version here https://apt.datadoghq.com/pool/d/da/

agentversion=$1

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd $SCRIPTS_DIR

CURRENT_AGENT=$(find . -type f -name "trace-agent*")

if [ -z "$CURRENT_AGENT" ]; then
    echo "Removing $CURRENT_AGENT"
    rm -f "$CURRENT_AGENT"
fi

# create temp directory
temp="$PWD/tmp"
mkdir "$temp"

# set name of trace agent
prefix="datadog-agent"
suffix=".deb"
agentname=${agentversion#"$prefix"}
agentname=${agentname%"$suffix"}

echo "Downloading and unarchiving agent"
curl -L "https://s3.amazonaws.com/apt.datadoghq.com/pool/d/da/$agentversion" -o "$temp"/agent.deb
cd "$temp" && tar -xf agent.deb && tar -xf data.tar.gz
mv "$temp"/opt/datadog-agent/embedded/bin/trace-agent ../trace-agent"$agentname"

echo "Exiting script"
trap 'rm -rf $temp' EXIT
