DEVELOPMENT_VERSION="0.2.117-prerelease"
AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-7.51.0-1-x86_64.zip"
TRACER_DOWNLOAD_URL="https://apmdotnetci.blob.core.windows.net/apm-dotnet-ci-artifacts-master/INSTALL_SHA/windows-tracer-home.zip"


echo "Downloading tracer from ${TRACER_DOWNLOAD_URL}"
wget -O tracer.zip $TRACER_DOWNLOAD_URL
if [ $? -ne 0 ]; then
    exit 1;
fi

echo "Unzipping tracer"
unzip tracer.zip -d dotnet/content/Tracer

DEVELOPMENT_VERSION_FILE=$( echo ${DEVELOPMENT_VERSION} | tr '.' '_' )
DEVELOPMENT_DIR=dotnet/content/v${DEVELOPMENT_VERSION_FILE}

echo "Downloading agent from ${AGENT_DOWNLOAD_URL}"
wget -O agent.zip $AGENT_DOWNLOAD_URL
if [ $? -ne 0 ]; then
    exit 1;
fi

unzip agent.zip -d dotnet-agent-extract

echo "Moving agent executables"
mv dotnet-agent-extract/bin/agent/dogstatsd.exe dotnet/content/Agent
mv dotnet-agent-extract/bin/agent/trace-agent.exe dotnet/content/Agent/datadog-trace-agent.exe

echo "Versioning development files"
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dotnet/content/Agent/datadog.yaml
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dotnet/content/Agent/dogstatsd.yaml
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dotnet/content/applicationHost.xdt
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dotnet/content/install.cmd
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dotnet/content/install.ps1
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" dotnet/content/applicationHost.xdt
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" dotnet/content/install.cmd
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" dotnet/content/install.ps1

echo "Moving content to development versioned folder"
mkdir $DEVELOPMENT_DIR
mv -v dotnet/content/Tracer $DEVELOPMENT_DIR/Tracer
mv -v dotnet/content/Agent $DEVELOPMENT_DIR/Agent

echo "Creating development nuget package"
echo "Packing nuspec file via arcane roundabout csproj process"
dotnet pack dotnet/DevelopmentVerification.DdDotNet.Apm.csproj -p:Version=${DEVELOPMENT_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package
