## Releasing a new version
To release a new version of the java extension, update the release and dev version in `/java/build-packages.sh`. If you want to use a newer agent or tracer version, update their github URLs as well.

Once the versions are updated, run `./java/build-packages.sh` from the parent directory. This will create a `.nupkg` file in `\packages`.

Upload the new dev package to nuget package management via the browser by following [this link](https://www.nuget.org/packages/manage/upload). Update the self-monitoring app with the new pre-release, prior to uploading the new release version.

Make sure to not commit or save the changes made after running the script, since placeholder values will be updated to match the release and dev versions.
