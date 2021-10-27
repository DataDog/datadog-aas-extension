
RELEASE_VERSION="0.1.0"
DEVELOPMENT_VERSION="0.1.0-prerelease"
AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-7.31.1-1-x86_64.zip" 
TRACER_DOWNLOAD_URL="https://github.com/DataDog/dd-trace-java/releases/download/v0.89.0/dd-java-agent.jar"

RELEASE_VERSION_FILE=$( echo ${RELEASE_VERSION} | tr '.' '_' )
DEVELOPMENT_VERSION_FILE=$( echo ${DEVELOPMENT_VERSION} | tr '.' '_' )
AGENT_CONFIG_DIR=$CI_PROJECT_DIR/java/content/Agent
BASE_DIR=$CI_PROJECT_DIR/java/content/
RELEASE_DIR=$CI_PROJECT_DIR/java/content/v${RELEASE_VERSION_FILE}
RELEASE_TRACER_DIR=$CI_PROJECT_DIR/java/content/v${RELEASE_VERSION_FILE}/Tracer
RELEASE_AGENT_DIR=$CI_PROJECT_DIR/java/content/v${RELEASE_VERSION_FILE}/Agent
DEVELOPMENT_DIR=$CI_PROJECT_DIR/java/content/v${DEVELOPMENT_VERSION_FILE}

echo "Downloading agent from ${AGENT_DOWNLOAD_URL}"
wget -O agent.zip $AGENT_DOWNLOAD_URL
unzip agent.zip -d agent-extract

echo "Creating folders for agent and tracer binaries"
mkdir $RELEASE_DIR
mkdir $RELEASE_TRACER_DIR
mkdir $RELEASE_AGENT_DIR

echo "Downloading tracer from ${TRACER_DOWNLOAD_URL} to ${RELEASE_TRACER_DIR}"
wget -O $RELEASE_TRACER_DIR/dd-java-agent.jar $TRACER_DOWNLOAD_URL

echo "Moving agent executables"
mv -v $AGENT_CONFIG_DIR/* $RELEASE_AGENT_DIR
mv agent-extract/bin/agent/dogstatsd.exe $RELEASE_AGENT_DIR
mv agent-extract/bin/agent/trace-agent.exe agent-extract/bin/agent/datadog-trace-agent.exe
mv agent-extract/bin/agent/datadog-trace-agent.exe $RELEASE_AGENT_DIR

echo "Versioning files"
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" java/content/applicationHost.xdt
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" java/content/install.cmd
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" java/content/install.ps1
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" java/content/applicationHost.xdt
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" java/content/install.cmd
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" java/content/install.ps1

echo "Creating nuget package"
echo "Packing nuspec file via arcane roundabout csproj process"
dotnet pack java/Datadog.AzureAppServices.Java.csproj -p:Version=${RELEASE_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package

echo "Updating versions from v${RELEASE_VERSION} to v${DEVELOPMENT_VERSION} for testing package"
sed -i "s/v${RELEASE_VERSION_FILE}/v${DEVELOPMENT_VERSION_FILE}/g" $RELEASE_AGENT_DIR/datadog.yaml
sed -i "s/v${RELEASE_VERSION_FILE}/v${DEVELOPMENT_VERSION_FILE}/g" $RELEASE_AGENT_DIR/dogstatsd.yaml
sed -i "s/v${RELEASE_VERSION_FILE}/v${DEVELOPMENT_VERSION_FILE}/g" java/content/applicationHost.xdt
sed -i "s/v${RELEASE_VERSION_FILE}/v${DEVELOPMENT_VERSION_FILE}/g" $BASE_DIR/install.cmd
sed -i "s/v${RELEASE_VERSION_FILE}/v${DEVELOPMENT_VERSION_FILE}/g" $BASE_DIR/install.ps1
sed -i "s/v${RELEASE_VERSION}/v${DEVELOPMENT_VERSION}/g" java/content/applicationHost.xdt
sed -i "s/v${RELEASE_VERSION}/v${DEVELOPMENT_VERSION}/g" $BASE_DIR/install.cmd
sed -i "s/v${RELEASE_VERSION}/v${DEVELOPMENT_VERSION}/g" $BASE_DIR/install.ps1

echo "Updating paths from Datadog.AzureAppServices.Java to DevelopmentVerification.DdJava.Apm for testing package"
sed -i 's/Datadog.AzureAppServices.Java/DevelopmentVerification.DdJava.Apm/g' $BASE_DIR/applicationHost.xdt
mkdir $DEVELOPMENT_DIR
mv -v $RELEASE_DIR/* $DEVELOPMENT_DIR
rm -d -v $RELEASE_DIR
dotnet pack java/DevelopmentVerification.DdJava.Apm.csproj -p:Version=${DEVELOPMENT_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package
