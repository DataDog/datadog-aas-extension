#!/usr/bin/env bash

# If UPDATE_AGENT=true, you must also provide an AGENT_VERSION, e.g. datadog-agent_7.38.2-1_amd64.deb.
# check for the latest version here https://apt.datadoghq.com/pool/d/da/

# Add the agent
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd $SCRIPTS_DIR/

if [ -n "$UPDATE_AGENT" ]; then
    if [ -n "$AGENT_VERSION" ]; then
        ./update-agent.sh "$AGENT_VERSION"

        AGENT=$(find . -type f -name "trace-agent*")

        cp $AGENT ../../dotnet/linux/datadog-aas-dotnet-linux/trace-agent
        cp $AGENT ../../node/linux/datadog-aas-node-linux/trace-agent

    else
        echo "Please provide an Agent Version"
        exit 1
    fi

fi

# Dotnet
# Build and add the Startup Hook
cd ../../dotnet/linux/startup-hook
dotnet restore && dotnet build

cp "$PWD"/bin/Debug/net6.0/datadog-startup-hook.dll ../datadog-aas-dotnet-linux/

#zip the packages
cd ../
zip -r datadog-aas-dotnet-linux datadog-aas-dotnet-linux

cd ../../node/linux/
zip -r datadog-aas-node-linux datadog-aas-node-linux
