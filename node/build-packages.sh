# TODO: build dll on windows machine then investigate how to do so in a pipeline
# TODO: build dlls for 32 bit and 64 bit
# TODO: add code for agent process manager to repo

ENV="dev"
AGENT_VERSION="7.50.3"
TRACER_VERSION="5.2.0"

while getopts e:v:a:t: flag
do
    case "${flag}" in
        e) ENV=${OPTARG};; # determines nuget package name and adds "prerelease" to version
        v) VERSION=${OPTARG};; 
        a) AGENT_VERSION=${OPTARG};;
        t) TRACER_VERSION=${OPTARG};;
    esac
done

if [ -z "$VERSION" ]; then
    echo "Must set semantic version"
    exit 1
fi

if [ "$ENV" = "dev" ]; then
    VERSION+="-prerelease"
fi

AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-${AGENT_VERSION}-1-x86_64.zip"

NUGET_DIR=node/content
DOWNLOADS_DIR=node/downloads

VERSION_FILE=$(echo ${VERSION} | tr '.' '_')
VERSION_DIR=$NUGET_DIR/v${VERSION_FILE}

rm -rf $NUGET_DIR
mkdir -p $VERSION_DIR/{Agent,Tracer}

echo "Installing tracer"
npm install --prefix $VERSION_DIR/Tracer dd-trace@${TRACER_VERSION}

echo "Downloading agent from ${AGENT_DOWNLOAD_URL}"
wget -O $DOWNLOADS_DIR/agent.zip $AGENT_DOWNLOAD_URL
if [ $? -ne 0 ]; then
    exit 1;
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
sed -i "s/vUNKNOWN/v${VERSION}/g" $NUGET_DIR/applicationHost.xdt
sed -i "s/vUNKNOWN/v${VERSION}/g" $NUGET_DIR/install.cmd
sed -i "s/vUNKNOWN/v${VERSION}/g" $NUGET_DIR/install.ps1

echo "Building process_manager"
cd node/process_manager # TODO: fix so cd is not necessary
cargo build --release --target=x86_64-pc-windows-gnu
cd ../..

echo "Moving process_manager"
cp node/process_manager/target/x86_64-pc-windows-gnu/release/process_manager.exe $NUGET_DIR/

echo "Creating nuget package"
if [ "$ENV" = "dev" ]; then
    dotnet pack node/DevelopmentVerification.DdNode.Apm.csproj -p:Version=${VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package
else
    dotnet pack node/Datadog.AzureAppServices.Node.Apm.csproj -p:Version=${VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package
fi
