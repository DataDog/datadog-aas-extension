
RELEASE_VERSION="1.8.0"
DEVELOPMENT_VERSION="0.1.44-prerelease"
AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-7.31.1-1-x86_64.zip" 
TRACER_DOWNLOAD_URL="https://github.com/DataDog/dd-trace-dotnet/releases/download/v1.29.0/windows-tracer-home.zip"

RELEASE_VERSION_FILE=$( echo ${RELEASE_VERSION:1} | tr '.' '_' )
DEVELOPMENT_VERSION_FILE=$( echo ${DEVELOPMENT_VERSION:1} | tr '.' '_' )
AGENT_CONFIG_DIR=$CI_PROJECT_DIR/dotnet/content/Agent
BASE_DIR=$CI_PROJECT_DIR/dotnet/content/
RELEASE_DIR=$CI_PROJECT_DIR/dotnet/content/v${RELEASE_VERSION_FILE}
RELEASE_TRACER_DIR=$CI_PROJECT_DIR/dotnet/content/v${RELEASE_VERSION_FILE}/Tracer
RELEASE_AGENT_DIR=$CI_PROJECT_DIR/dotnet/content/v${RELEASE_VERSION_FILE}/Agent
DEVELOPMENT_DIR=$CI_PROJECT_DIR/dotnet/content/v${DEVELOPMENT_VERSION_FILE}

echo "Packaging release version ${RELEASE_VERSION} [${RELEASE_VERSION_FILE}]"
echo "Packaging development version ${DEVELOPMENT_VERSION} [${DEVELOPMENT_VERSION_FILE}]"
echo "Downloading agent from ${AGENT_DOWNLOAD_URL}"
wget -O agent.zip $AGENT_DOWNLOAD_URL
unzip agent.zip -d dotnet-agent-extract
echo "Downloading tracer from ${TRACER_DOWNLOAD_URL}"
wget -O tracer.zip $TRACER_DOWNLOAD_URL
unzip tracer.zip -d dotnet-tracer-extract
echo "Moving agent executables and tracer binaries"
mkdir $RELEASE_DIR
mkdir $RELEASE_TRACER_DIR
mkdir $RELEASE_AGENT_DIR
mv -v dotnet-tracer-extract/* $RELEASE_TRACER_DIR
mv -v $AGENT_CONFIG_DIR/* $RELEASE_AGENT_DIR
mv dotnet-agent-extract/bin/agent/dogstatsd.exe $RELEASE_AGENT_DIR
mv dotnet-agent-extract/bin/agent/trace-agent.exe dotnet-agent-extract/bin/agent/datadog-trace-agent.exe
mv dotnet-agent-extract/bin/agent/datadog-trace-agent.exe $RELEASE_AGENT_DIR
sed -i 's/vUNKNOWN/v${RELEASE_VERSION}/g' $BASE_DIR/install.cmd
echo "Creating nuget package"
echo "Packing nuspec file via arcane roundabout csproj process"
dotnet pack dotnet/Datadog.AzureAppServices.DotNet.csproj -p:Version=${RELEASE_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package
echo "Updating versions from v${RELEASE_VERSION} to v${DEVELOPMENT_VERSION} for testing package"
sed -i 's/v${RELEASE_VERSION_FILE}/v${DEVELOPMENT_VERSION_FILE}/g' dotnet/content/applicationHost.xdt
sed -i 's/EXTENSION_VERSION" value="${RELEASE_VERSION}"/EXTENSION_VERSION" value="${RELEASE_VERSION}"/g' dotnet/content/applicationHost.xdt
sed -i 's/v${RELEASE_VERSION_FILE}/v${DEVELOPMENT_VERSION_FILE}/g' $RELEASE_AGENT_DIR/datadog.yaml
sed -i 's/v${RELEASE_VERSION_FILE}/v${DEVELOPMENT_VERSION_FILE}/g' $RELEASE_AGENT_DIR/dogstatsd.yaml
sed -i 's/v${RELEASE_VERSION}/v${DEVELOPMENT_VERSION}/g' $BASE_DIR/install.cmd
echo "Updating paths from Datadog.AzureAppServices.DotNet to DevelopmentVerification.DdDotNet.Apm for testing package"
sed -i 's/Datadog.AzureAppServices.DotNet/DevelopmentVerification.DdDotNet.Apm/g' $BASE_DIR/applicationHost.xdt
mkdir $DEVELOPMENT_DIR
mv -v $RELEASE_DIR/* $DEVELOPMENT_DIR
rm -d -v $RELEASE_DIR
dotnet pack dotnet/DevelopmentVerification.DdDotNet.Apm.csproj -p:Version=${DEVELOPMENT_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package
