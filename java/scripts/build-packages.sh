if [[ -z ${RELEASE_VERSION+x} ]] || [[ -z ${DEVELOPMENT_VERSION+x} ]]; then
    echo "RELEASE_VERSION and DEVELOPMENT_VERSION environment variables must both be set"
    exit 1
fi

AGENT_VERSION="7.60.1"
TRACER_VERSION="1.47.3"

echo "Building version ${RELEASE_VERSION} for prod environment"
echo "Building version ${DEVELOPMENT_VERSION} for dev environment"

RELEASE_DIR=java/content
DEVELOPMENT_DIR=java/dev/content

RELEASE_VERSION_FILE=$(echo ${RELEASE_VERSION} | tr '.' '_')
RELEASE_VERSION_DIR=$RELEASE_DIR/v${RELEASE_VERSION_FILE}

DEVELOPMENT_VERSION_FILE=$(echo ${DEVELOPMENT_VERSION} | tr '.' '_')
DEVELOPMENT_VERSION_DIR=$DEVELOPMENT_DIR/v${DEVELOPMENT_VERSION_FILE}

rm -rf $RELEASE_DIR
mkdir -p $RELEASE_VERSION_DIR/{Agent,Tracer}

rm -rf $DEVELOPMENT_DIR
mkdir -p $DEVELOPMENT_VERSION_DIR/{Agent,Tracer}

TRACER_DOWNLOAD_URL="https://github.com/DataDog/dd-trace-java/releases/download/v${TRACER_VERSION}/dd-java-agent-${TRACER_VERSION}.jar"
DOWNLOADS_DIR=java/downloads

echo "Downloading tracer from ${TRACER_DOWNLOAD_URL}"
curl -L -o $DOWNLOADS_DIR/dd-java-agent.jar --create-dirs $TRACER_DOWNLOAD_URL
if [ $? -ne 0 ]; then
    exit 1
fi

AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-${AGENT_VERSION}-1-x86_64.zip"

echo "Downloading agent from ${AGENT_DOWNLOAD_URL}"
curl -o $DOWNLOADS_DIR/agent.zip --create-dirs $AGENT_DOWNLOAD_URL
if [ $? -ne 0 ]; then
    exit 1
fi

unzip -o $DOWNLOADS_DIR/agent.zip -d $DOWNLOADS_DIR/java-agent-extract

echo "Moving tracer jar"
cp $DOWNLOADS_DIR/dd-java-agent.jar $RELEASE_VERSION_DIR/Tracer
cp $DOWNLOADS_DIR/dd-java-agent.jar $DEVELOPMENT_VERSION_DIR/Tracer

echo "Moving agent executables"
cp $DOWNLOADS_DIR/java-agent-extract/bin/agent/dogstatsd.exe $RELEASE_VERSION_DIR/Agent
cp $DOWNLOADS_DIR/java-agent-extract/bin/agent/trace-agent.exe $RELEASE_VERSION_DIR/Agent/datadog-trace-agent.exe

cp $DOWNLOADS_DIR/java-agent-extract/bin/agent/dogstatsd.exe $DEVELOPMENT_VERSION_DIR/Agent
cp $DOWNLOADS_DIR/java-agent-extract/bin/agent/trace-agent.exe $DEVELOPMENT_VERSION_DIR/Agent/datadog-trace-agent.exe

echo "Copying configuration files"
rsync --exclude=Agent java/src/* $RELEASE_DIR
cp java/src/Agent/* $RELEASE_VERSION_DIR/Agent

rsync --exclude=Agent java/src/* $DEVELOPMENT_DIR
cp java/src/Agent/* $DEVELOPMENT_VERSION_DIR/Agent

echo "Versioning configuration files"
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" $RELEASE_VERSION_DIR/Agent/datadog.yaml
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" $RELEASE_VERSION_DIR/Agent/dogstatsd.yaml
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" $RELEASE_DIR/applicationHost.xdt
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" $RELEASE_DIR/install.ps1
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" $RELEASE_DIR/applicationHost.xdt
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" $RELEASE_DIR/install.cmd

sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" $DEVELOPMENT_VERSION_DIR/Agent/datadog.yaml
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" $DEVELOPMENT_VERSION_DIR/Agent/dogstatsd.yaml
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" $DEVELOPMENT_DIR/applicationHost.xdt
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" $DEVELOPMENT_DIR/install.ps1
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" $DEVELOPMENT_DIR/applicationHost.xdt
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" $DEVELOPMENT_DIR/install.cmd

echo "Building nuget packages"
dotnet pack java/Datadog.AzureAppServices.Java.Apm.csproj -p:Version=${RELEASE_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package
dotnet pack java/DevelopmentVerification.DdJava.Apm.csproj -p:Version=${DEVELOPMENT_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package
