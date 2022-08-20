## Development information

You can build locally the extension by using ./dotnet/build-packages-local.sh
It will both build the application and upload to a dev nuget feed that you can use on your app. This feed can be used by setting the variable `SCM_SITEEXTENSIONS_FEED_URL` to `https://pkgs.dev.azure.com/datadoghq/dd-trace-dotnet/_packaging/Public_Feed/nuget/v2` in your app.