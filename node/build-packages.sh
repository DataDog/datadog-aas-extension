# TODO: Parameterize dev/prod, version, agent binary version, and tracer version
# TODO: configure applicationHost.xdt file
# TODO: build dll on windows machine then investigate how to do so in a pipeline

VERSION="1.0.0"
AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-7.50.3-1-x86_64.zip"

VERSION_FILE=$(echo ${VERSION} | tr '.' '_')
DIR=node/content/v${VERSION_FILE}

mkdir -p $DIR/{Agent,Tracer}

echo "Installing tracer"
npm install --prefix $DIR/Tracer dd-trace@5.2.0

echo "Downloading agent from ${AGENT_DOWNLOAD_URL}"
wget -O agent.zip $AGENT_DOWNLOAD_URL
if [ $? -ne 0 ]; then
    exit 1;
fi

unzip -o agent.zip -d node-agent-extract

echo "Moving agent executables"
mv node-agent-extract/bin/agent/dogstatsd.exe $DIR/Agent
mv node-agent-extract/bin/agent/trace-agent.exe $DIR/Agent

echo "Copying configuration files"
cp -r node/src/* $DIR/

echo "Versioning development files"
sed -i "s/vFOLDERUNKNOWN/v${VERSION_FILE}/g" $DIR/Agent/datadog.yaml
sed -i "s/vFOLDERUNKNOWN/v${VERSION_FILE}/g" $DIR/Agent/dogstatsd.yaml
sed -i "s/vUNKNOWN/v${VERSION}/g" $DIR/applicationHost.xdt
sed -i "s/vUNKNOWN/v${VERSION}/g" $DIR/install.cmd
sed -i "s/vUNKNOWN/v${VERSION}/g" $DIR/install.ps1

echo "Creating development nuget package"
dotnet pack node/DevelopmentVerification.DdNode.Apm.csproj -p:Version=${VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package