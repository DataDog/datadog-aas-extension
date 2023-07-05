RELEASE_VERSION="0.1.0"
DEVELOPMENT_VERSION="0.1.0-prerelease"
AGENT_DOWNLOAD_URL="http://s3.amazonaws.com/dsd6-staging/windows/agent7/buildpack/agent-binaries-7.35.2-1-x86_64.zip"
RUNTIME_NAME=node # remove

RELEASE_VERSION_FILE=$( echo ${RELEASE_VERSION} | tr '.' '_' )
DEVELOPMENT_VERSION_FILE=$( echo ${DEVELOPMENT_VERSION} | tr '.' '_' )
RELEASE_DIR=$CI_PROJECT_DIR/$RUNTIME_NAME/content/v${RELEASE_VERSION_FILE}
DEVELOPMENT_DIR=$CI_PROJECT_DIR/dev-$RUNTIME_NAME/content/v${DEVELOPMENT_VERSION_FILE}

echo "Downloading agent from ${AGENT_DOWNLOAD_URL}"
wget -O agent.zip $AGENT_DOWNLOAD_URL
unzip agent.zip -d agent-extract

echo "Moving agent executables"
mkdir $RUNTIME_NAME/content/Agent
mv agent-extract/bin/agent/dogstatsd.exe $RUNTIME_NAME/content/Agent
mv agent-extract/bin/agent/trace-agent.exe $RUNTIME_NAME/content/Agent/datadog-trace-agent.exe

echo "Copying files for development version"
cp -r ./$RUNTIME_NAME ./dev-$RUNTIME_NAME

echo "Versioning release files"
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" $RUNTIME_NAME/content/Agent/datadog.yaml
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" $RUNTIME_NAME/content/Agent/dogstatsd.yaml
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" $RUNTIME_NAME/content/applicationHost.xdt
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" $RUNTIME_NAME/content/install.cmd
sed -i "s/vFOLDERUNKNOWN/v${RELEASE_VERSION_FILE}/g" $RUNTIME_NAME/content/install.ps1
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" $RUNTIME_NAME/content/applicationHost.xdt
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" $RUNTIME_NAME/content/install.cmd
sed -i "s/vUNKNOWN/v${RELEASE_VERSION}/g" $RUNTIME_NAME/content/install.ps1

echo "Moving content to versioned folder"
mkdir -p $RELEASE_DIR
# mv -v $RUNTIME_NAME/content/Tracer $RELEASE_DIR/Tracer
mv -v $RUNTIME_NAME/content/Agent $RELEASE_DIR/Agent

echo "Creating release nuget package"
echo "Packing nuspec file via arcane roundabout csproj process"
dotnet pack $RUNTIME_NAME/Datadog.AzureAppServices.Node.csproj -p:Version=${RELEASE_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package

echo "Versioning development files"
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-$RUNTIME_NAME/content/Agent/datadog.yaml
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-$RUNTIME_NAME/content/Agent/dogstatsd.yaml
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-$RUNTIME_NAME/content/applicationHost.xdt
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-$RUNTIME_NAME/content/install.cmd
sed -i "s/vFOLDERUNKNOWN/v${DEVELOPMENT_VERSION_FILE}/g" dev-$RUNTIME_NAME/content/install.ps1
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" dev-$RUNTIME_NAME/content/applicationHost.xdt
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" dev-$RUNTIME_NAME/content/install.cmd
sed -i "s/vUNKNOWN/v${DEVELOPMENT_VERSION}/g" dev-$RUNTIME_NAME/content/install.ps1

echo "Updating paths from Datadog.AzureAppServices.Node to DevelopmentVerification.DdNode.Apm for testing package"
sed -i 's/Datadog.AzureAppServices.Node/DevelopmentVerification.DdNode.Apm/g' dev-$RUNTIME_NAME/content/applicationHost.xdt

echo "Moving content to development versioned folder"
mkdir $DEVELOPMENT_DIR
# mv -v dev-$RUNTIME_NAME/content/Tracer $DEVELOPMENT_DIR/Tracer
mv -v dev-$RUNTIME_NAME/content/Agent $DEVELOPMENT_DIR/Agent

echo "Creating development nuget package"
echo "Packing nuspec file via arcane roundabout csproj process"
dotnet pack dev-$RUNTIME_NAME/DevelopmentVerification.DdNode.Apm.csproj -p:Version=${DEVELOPMENT_VERSION} -p:NoBuild=true -p:NoDefaultExcludes=true -o package