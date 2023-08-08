#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <Node|Java|DotNet>"
    exit 1
fi

DEVELOPMENT_VERSION="0.0.4"
AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-7.46.0-1-x86_64.zip"
RUNTIME="$1"
OS_NAME=windows

DEVELOPMENT_VERSION_FILE=$( echo ${DEVELOPMENT_VERSION} | tr '.' '_' )
DEVELOPMENT_DIR=$OS_NAME/content/v${DEVELOPMENT_VERSION_FILE}

mkdir -p $OS_NAME/content/Tracer
if [ "$RUNTIME" = "Node" ]; then
    echo "Downloading Node Tracer"
    npm install --prefix $OS_NAME/content/Tracer dd-trace
elif [ "$RUNTIME" = "Java" ]; then
    TRACER_DOWNLOAD_URL="https://github.com/DataDog/dd-trace-java/releases/latest/download/dd-java-agent.jar"

    echo "Downloading tracer from ${TRACER_DOWNLOAD_URL}"
    wget -O $OS_NAME/content/Tracer/dd-java-agent.jar $TRACER_DOWNLOAD_URL
elif [ "$RUNTIME" = "DotNet" ]; then
    TRACER_DOWNLOAD_URL="https://github.com/DataDog/dd-trace-dotnet/releases/latest/download/windows-tracer-home.zip"

    echo "Downloading tracer from ${TRACER_DOWNLOAD_URL}"
    wget -O tracer.zip $TRACER_DOWNLOAD_URL
    if [ $? -ne 0 ]; then
        exit 1;
    fi

    echo "Unzipping tracer"
    unzip tracer.zip -d $OS_NAME/content/Tracer
    if [ $? -ne 0 ]; then
        exit 1;
    fi
else
    echo "Unsupported runtime: $RUNTIME"
    echo "Usage: $0 <Node|Java|DotNet>"
    exit 1
fi

echo "Downloading agent from ${AGENT_DOWNLOAD_URL}"
wget -O agent.zip $AGENT_DOWNLOAD_URL
if [ $? -ne 0 ]; then
    exit 1;
fi

unzip agent.zip -d agent-extract

echo "Moving agent executables"
mv agent-extract/bin/agent/dogstatsd.exe $OS_NAME/content/Agent
mv agent-extract/bin/agent/trace-agent.exe $OS_NAME/content/Agent

echo "Building process_manager"
cd $OS_NAME/process_manager
cargo build --release --target=x86_64-pc-windows-gnu

echo "Moving process_manager"
cd ../..
mv $OS_NAME/process_manager/target/x86_64-pc-windows-gnu/release/process_manager.exe $OS_NAME/content/process_manager.exe

echo "Versioning development files"
sed -i "" "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" $OS_NAME/content/Agent/datadog.yaml
sed -i "" "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" $OS_NAME/content/Agent/dogstatsd.yaml
sed -i "" "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" $OS_NAME/content/applicationHost.xdt
sed -i "" "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" $OS_NAME/content/applicationHost.xdt
sed -i "" "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" $OS_NAME/content/install.cmd
sed -i "" "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" $OS_NAME/content/install.ps1
sed -i "" "s/RUNTIME_PLACEHOLDER/${RUNTIME}/g" $OS_NAME/content/applicationHost.xdt
sed -i "" "s/RUNTIME_PLACEHOLDER/${RUNTIME}/g" $OS_NAME/content/install.cmd

echo "Moving content to development versioned folder"
mkdir $DEVELOPMENT_DIR
mv -v $OS_NAME/content/Tracer $DEVELOPMENT_DIR/Tracer
mv -v $OS_NAME/content/Agent $DEVELOPMENT_DIR/Agent
mv -v $OS_NAME/content/AgentProcessManager.dll $DEVELOPMENT_DIR/AgentProcessManager.dll

find $OS_NAME -name '.DS_Store' -type f -delete

echo "Creating development nuget package"
echo "Packing nuspec file via arcane roundabout csproj process"
dotnet pack $OS_NAME/Datadog.AzureAppServices.$RUNTIME.csproj -p:Version=${DEVELOPMENT_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package

echo "Cleanup"
rm -rfv agent-extract agent.zip **/content/v*