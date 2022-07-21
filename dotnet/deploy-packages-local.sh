INSTALL_SHA="38787d2e9cadd408f541675e95fab7b9a687d559"
PACKAGE_BUILD_VERSION="0.2.659679454"

# Handle later the possibility to use a local commit
./dotnet/build-packages-dev.sh $PACKAGE_BUILD_VERSION $INSTALL_SHA
# SET AZDO_PAT in external env variable as it's a secret 
./dotnet/upload-dev-nuget.sh $PACKAGE_BUILD_VERSION $AZDO_PAT 