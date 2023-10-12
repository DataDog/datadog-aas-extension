#!/bin/bash
RELEASE_VERSION="1.0.0"
DEVELOPMENT_VERSION="1.0.0-prerelease"
AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-7.47.0-1-x86_64.zip"
TRACER_DOWNLOAD_URL="https://github.com/DataDog/dd-trace-java/releases/download/v1.20.1/dd-java-agent-1.20.1.jar"

echo "Downloading tracer from ${TRACER_DOWNLOAD_URL}"
mkdir java/content/Tracer
wget -O java/content/Tracer/dd-java-agent.jar $TRACER_DOWNLOAD_URL

RELEASE_VERSION_FILE=$( echo ${RELEASE_VERSION} | tr '.' '_' )
DEVELOPMENT_VERSION_FILE=$( echo ${DEVELOPMENT_VERSION} | tr '.' '_' )
RELEASE_DIR=java/content/v${RELEASE_VERSION_FILE}
DEVELOPMENT_DIR=dev-java/content/v${DEVELOPMENT_VERSION_FILE}

echo "Downloading agent from ${AGENT_DOWNLOAD_URL}"
wget -O agent.zip $AGENT_DOWNLOAD_URL
unzip agent.zip -d java-agent-extract

echo "Moving agent executables"
mkdir java/content/Agent
mv java-agent-extract/bin/agent/dogstatsd.exe java/content/Agent
mv java-agent-extract/bin/agent/trace-agent.exe java/content/Agent/datadog-trace-agent.exe

echo "Copying files for development version"
mkdir dev-java
cp -r java/* dev-java/

echo "Versioning release files"
sed -i '' -e "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" java/content/Agent/datadog.yaml
sed -i '' -e "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" java/content/Agent/dogstatsd.yaml
sed -i '' -e "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" java/content/applicationHost.xdt
sed -i '' -e "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" java/content/install.cmd
sed -i '' -e "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" java/content/install.ps1
sed -i '' -e "s/vUNKNOWN/v${RELEASE_VERSION}/g" java/content/applicationHost.xdt
sed -i '' -e "s/vUNKNOWN/v${RELEASE_VERSION}/g" java/content/install.cmd
sed -i '' -e "s/vUNKNOWN/v${RELEASE_VERSION}/g" java/content/install.ps1

echo "Moving content to versioned folder"
mkdir $RELEASE_DIR
mv -v java/content/Tracer $RELEASE_DIR/Tracer
mv -v java/content/Agent $RELEASE_DIR/Agent

echo "Creating release nuget package"
echo "Packing nuspec file via arcane roundabout csproj process"
dotnet pack java/Datadog.AzureAppServices.Java.csproj -p:Version=${RELEASE_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package

echo "Versioning development files"
sed -i '' -e "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-java/content/Agent/datadog.yaml
sed -i '' -e "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-java/content/Agent/dogstatsd.yaml
sed -i '' -e "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-java/content/applicationHost.xdt
sed -i '' -e "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-java/content/install.cmd
sed -i '' -e "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-java/content/install.ps1
sed -i '' -e "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" dev-java/content/applicationHost.xdt
sed -i '' -e "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" dev-java/content/install.cmd
sed -i '' -e "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" dev-java/content/install.ps1

echo "Updating paths from Datadog.AzureAppServices.Java to DevelopmentVerification.DdJava.Apm for testing package"
sed -i '' -e 's/Datadog.AzureAppServices.Java/DevelopmentVerification.DdJava.Apm/g' dev-java/content/applicationHost.xdt

echo "Moving content to development versioned folder"
mkdir $DEVELOPMENT_DIR
mv -v dev-java/content/Tracer $DEVELOPMENT_DIR/Tracer
mv -v dev-java/content/Agent $DEVELOPMENT_DIR/Agent

echo "Creating development nuget package"
echo "Packing nuspec file via arcane roundabout csproj process"
dotnet pack dev-java/DevelopmentVerification.DdJava.Apm.csproj -p:Version=${DEVELOPMENT_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package

echo "Cleanup"
rm -rfv java-agent-extract agent-extract agent.zip dev-java java/content/v* 1> /dev/null