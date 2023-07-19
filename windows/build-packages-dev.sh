DEVELOPMENT_VERSION="0.1.18-prerelease"
AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-7.46.0-1-x86_64.zip"
RUNTIME_NAME=windows

DEVELOPMENT_VERSION_FILE=$( echo ${DEVELOPMENT_VERSION} | tr '.' '_' )
DEVELOPMENT_DIR=$RUNTIME_NAME/content/v${DEVELOPMENT_VERSION_FILE}

echo "Downloading agent from ${AGENT_DOWNLOAD_URL}"
wget -O agent.zip $AGENT_DOWNLOAD_URL
if [ $? -ne 0 ]; then
    exit 1;
fi

unzip agent.zip -d agent-extract

echo "Moving agent executables"
mkdir -p $RUNTIME_NAME/content/Agent
mv agent-extract/bin/agent/dogstatsd.exe $RUNTIME_NAME/content/Agent
mv agent-extract/bin/agent/trace-agent.exe $RUNTIME_NAME/content/Agent

echo "Versioning development files"
sed -i "" "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" $RUNTIME_NAME/content/Agent/datadog.yaml
sed -i "" "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" $RUNTIME_NAME/content/Agent/dogstatsd.yaml
sed -i "" "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" $RUNTIME_NAME/content/applicationHost.xdt
sed -i "" "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" $RUNTIME_NAME/content/install.cmd
sed -i "" "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" $RUNTIME_NAME/content/applicationHost.xdt
sed -i "" "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" $RUNTIME_NAME/content/install.cmd

echo "Moving content to development versioned folder"
mkdir $DEVELOPMENT_DIR
mv -v $RUNTIME_NAME/content/Agent $DEVELOPMENT_DIR/Agent
mv -v $RUNTIME_NAME/content/AgentProcessManager.dll $DEVELOPMENT_DIR/AgentProcessManager.dll

echo "Creating development nuget package"
echo "Packing nuspec file via arcane roundabout csproj process"
dotnet pack windows/DevelopmentVerification.DdWindows.Apm.csproj -p:Version=${DEVELOPMENT_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package

echo "Cleanup"
rm -rfv agent-extract agent.zip **/content/v*