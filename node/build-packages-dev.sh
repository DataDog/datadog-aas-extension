# TODO: Parameterize development version, agent binary version, and tracer version
# TODO: configure applicationHost.xdt file
# TODO: build dll on windows machine then investigate how to do so in a pipeline

DEVELOPMENT_VERSION="1.0.0"
AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-7.50.3-1-x86_64.zip"

DEVELOPMENT_VERSION_FILE=$(echo ${DEVELOPMENT_VERSION} | tr '.' '_')
DEVELOPMENT_DIR=node/content/v${DEVELOPMENT_VERSION_FILE}

mkdir -p $DEVELOPMENT_DIR/{Agent,Tracer}

echo "Installing tracer"
npm install --prefix $DEVELOPMENT_DIR/Tracer dd-trace@5.2.0

# echo "Downloading agent from ${AGENT_DOWNLOAD_URL}"
# wget -O agent.zip $AGENT_DOWNLOAD_URL
# if [ $? -ne 0 ]; then
#     exit 1;
# fi

unzip -o agent.zip -d node-agent-extract

echo "Moving agent executables"
mv node-agent-extract/bin/agent/dogstatsd.exe $DEVELOPMENT_DIR/Agent
mv node-agent-extract/bin/agent/trace-agent.exe $DEVELOPMENT_DIR/Agent

echo "Copying configuration files"
cp -r node/src/* $DEVELOPMENT_DIR/

echo "Versioning development files"
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" $DEVELOPMENT_DIR/Agent/datadog.yaml
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" $DEVELOPMENT_DIR/Agent/dogstatsd.yaml
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" $DEVELOPMENT_DIR/applicationHost.xdt
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" $DEVELOPMENT_DIR/install.cmd
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" $DEVELOPMENT_DIR/install.ps1

# echo "Creating development nuget package"
# echo "Packing nuspec file via arcane roundabout csproj process"
# dotnet pack node/DevelopmentVerification.DdNode.Apm.csproj -p:Version=${DEVELOPMENT_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package
