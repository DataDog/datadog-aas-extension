
RELEASE_VERSION="1.9.2"
DEVELOPMENT_VERSION="0.1.54-prerelease"
AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-7.32.0-1-x86_64.zip" 
TRACER_DOWNLOAD_URL="https://github.com/DataDog/dd-trace-dotnet/releases/download/v1.30.1/windows-tracer-home.zip"

echo "Downloading tracer from ${TRACER_DOWNLOAD_URL}"
wget -O tracer.zip $TRACER_DOWNLOAD_URL
echo "Unzipping tracer"
unzip tracer.zip -d dotnet/content/Tracer

RELEASE_VERSION_FILE=$( echo ${RELEASE_VERSION} | tr '.' '_' )
DEVELOPMENT_VERSION_FILE=$( echo ${DEVELOPMENT_VERSION} | tr '.' '_' )
RELEASE_DIR=$CI_PROJECT_DIR/dotnet/content/v${RELEASE_VERSION_FILE}
DEVELOPMENT_DIR=$CI_PROJECT_DIR/dev-dotnet/content/v${DEVELOPMENT_VERSION_FILE}

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

echo "Versioning development files"
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-dotnet/content/Agent/datadog.yaml
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-dotnet/content/Agent/dogstatsd.yaml
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-dotnet/content/applicationHost.xdt
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-dotnet/content/install.cmd
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-dotnet/content/install.ps1
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" dev-dotnet/content/applicationHost.xdt
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" dev-dotnet/content/install.cmd
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" dev-dotnet/content/install.ps1

echo "Updating paths from Datadog.AzureAppServices.DotNet to DevelopmentVerification.DdDotNet.Apm for testing package"
sed -i 's/Datadog.AzureAppServices.DotNet/DevelopmentVerification.DdDotNet.Apm/g' dev-dotnet/content/applicationHost.xdt

echo "Moving content to development versioned folder"
mkdir $DEVELOPMENT_DIR
mv -v dev-dotnet/content/Tracer $DEVELOPMENT_DIR/Tracer
mv -v dev-dotnet/content/Agent $DEVELOPMENT_DIR/Agent

echo "Creating development nuget package"
echo "Packing nuspec file via arcane roundabout csproj process"
dotnet pack dev-dotnet/DevelopmentVerification.DdDotNet.Apm.csproj -p:Version=${DEVELOPMENT_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package
