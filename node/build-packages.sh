AGENT_VERSION="7.50.3"
TRACER_VERSION="5.2.0"

while getopts e:v: opt; do
    case $opt in
    # env sets nuget package name and adds "prerelease" to version
    e)
        if [[ $OPTARG == "dev" || $OPTARG == "prod" ]]; then
            ENV=$OPTARG
        else
            echo "Invalid argument for -e option: '${OPTARG}'. Allowed values are 'dev' or 'prod'" >&2
            exit 1
        fi
        ;;
    v)
        RELEASE_VERSION=$OPTARG
    esac
done

# Append prerelease for dev environment if not already added
if [ "$ENV" = "dev" ] && [[ "$RELEASE_VERSION" != *-prerelease ]]; then
    RELEASE_VERSION+="-prerelease"
fi

echo "Building version ${RELEASE_VERSION} for ${ENV} environment"

AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-${AGENT_VERSION}-1-x86_64.zip"

NUGET_DIR=node/content
DOWNLOADS_DIR=node/downloads

VERSION_FILE=$(echo ${RELEASE_VERSION} | tr '.' '_')
VERSION_DIR=$NUGET_DIR/v${VERSION_FILE}

rm -rf $NUGET_DIR
mkdir -p $VERSION_DIR/{Agent,Tracer}

echo "Installing tracer"
npm install --prefix $VERSION_DIR/Tracer dd-trace@${TRACER_VERSION}

echo "Downloading agent from ${AGENT_DOWNLOAD_URL}"
curl -o $DOWNLOADS_DIR/agent.zip --create-dirs $AGENT_DOWNLOAD_URL
if [ $? -ne 0 ]; then
    exit 1
fi

unzip -o $DOWNLOADS_DIR/agent.zip -d $DOWNLOADS_DIR/node-agent-extract

echo "Moving agent executables"
cp $DOWNLOADS_DIR/node-agent-extract/bin/agent/dogstatsd.exe $VERSION_DIR/Agent
cp $DOWNLOADS_DIR/node-agent-extract/bin/agent/trace-agent.exe $VERSION_DIR/Agent/datadog-trace-agent.exe

echo "Copying configuration files"
rsync --exclude=AgentProcessManager_*.dll --exclude=Agent node/src/* $NUGET_DIR
cp node/src/AgentProcessManager_*.dll $VERSION_DIR
cp node/src/Agent/* $VERSION_DIR/Agent

echo "Versioning configuration files"
sed -i "s/vFOLDERUNKNOWN/v${VERSION_FILE}/g" $VERSION_DIR/Agent/datadog.yaml
sed -i "s/vFOLDERUNKNOWN/v${VERSION_FILE}/g" $VERSION_DIR/Agent/dogstatsd.yaml
sed -i "s/vFOLDERUNKNOWN/v${VERSION_FILE}/g" $NUGET_DIR/applicationHost.xdt
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" $NUGET_DIR/applicationHost.xdt
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" $NUGET_DIR/install.cmd
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" $NUGET_DIR/install.ps1

echo "Moving process manager executable"
cp node/process_manager/target/x86_64-pc-windows-gnu/release/process_manager.exe $NUGET_DIR

echo "Creating nuget package"
if [ "$ENV" = "dev" ]; then
    dotnet pack node/DevelopmentVerification.DdNode.Apm.csproj -p:Version=${RELEASE_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package
else
    dotnet pack node/Datadog.AzureAppServices.Node.csproj -p:Version=${RELEASE_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package
fi
