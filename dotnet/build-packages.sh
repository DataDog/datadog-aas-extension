RELEASE_VERSION="3.24.100"
AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-7.60.1-1-x86_64.zip"
TRACER_DOWNLOAD_URL="https://github.com/DataDog/dd-trace-dotnet/releases/download/v3.24.1/windows-tracer-home.zip"

echo "Downloading tracer from ${TRACER_DOWNLOAD_URL}"
wget -O tracer.zip $TRACER_DOWNLOAD_URL
if [ $? -ne 0 ]; then
    exit 1;
fi

echo "Unzipping tracer"
unzip tracer.zip -d dotnet/content/Tracer
if [ $? -ne 0 ]; then
    exit 1;
fi

RELEASE_VERSION_FILE=$( echo ${RELEASE_VERSION} | tr '.' '_' )
RELEASE_DIR=$CI_PROJECT_DIR/dotnet/content/v${RELEASE_VERSION_FILE}

echo "Downloading agent from ${AGENT_DOWNLOAD_URL}"
wget -O agent.zip $AGENT_DOWNLOAD_URL
unzip agent.zip -d dotnet-agent-extract

echo "Moving agent executables"
mkdir dotnet/content/Agent
mv dotnet-agent-extract/bin/agent/dogstatsd.exe dotnet/content/Agent
mv dotnet-agent-extract/bin/agent/trace-agent.exe dotnet/content/Agent/datadog-trace-agent.exe

echo "Copying files for development version"
cp -r ./dotnet ./dev-dotnet

echo "Versioning release files"
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" dotnet/content/Agent/datadog.yaml
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" dotnet/content/Agent/dogstatsd.yaml
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" dotnet/content/applicationHost.xdt
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" dotnet/content/install.cmd
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" dotnet/content/install.ps1
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" dotnet/content/applicationHost.xdt
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" dotnet/content/install.cmd
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" dotnet/content/install.ps1

echo "Moving content to versioned folder"
mkdir $RELEASE_DIR
mv -v dotnet/content/Tracer $RELEASE_DIR/Tracer
mv -v dotnet/content/Agent $RELEASE_DIR/Agent

echo "Creating release nuget package"
echo "Packing nuspec file via arcane roundabout csproj process"
dotnet pack dotnet/Datadog.AzureAppServices.DotNet.csproj -p:Version=${RELEASE_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package
