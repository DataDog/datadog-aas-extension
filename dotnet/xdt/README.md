# Custom applicationHost.xdt for the .NET extension

App Service applies every site extension's `applicationHost.xdt` in one run each time a worker starts. If that run takes more than about 60 seconds, App Service drops every extension's changes. It does not log an error and doesn't retry, so the worker starts without extension config. A large number of XDT operations can easily take more than 60 seconds, especially under load. This folder holds a custom XDT transform that sets variables in one operation to reduce the chances of timeouts.

- `src/`: `SetEnvironmentVariables`, a `Microsoft.Web.XmlTransform.Transform`, built for .NET Framework 4.5 against `Microsoft.Web.XmlTransform` 1.4.0.0, the version in the App Service GAC. It never logs an error and never throws. On any problem it logs a warning and leaves the config unchanged, so other extensions keep their settings.
- `make-custom-xdt.py`: generates `../content/applicationHost.custom.xdt` from a standard `applicationHost.xdt`. Rerun it if there's drift between the standard and custom files.
- `../content/preflight.ps1`: called by `install.ps1` in Kudu at install time. It installs the one-step file only if this instance can load the DLL and there are no config differences. Otherwise it keeps the standard file.
- `tests/`: unit tests. `test-preflight.sh` checks the preflight's decisions locally under `pwsh`.

```sh
dotnet build -c Release dotnet/xdt/src
dotnet test dotnet/xdt/tests -p:XdtVersion=1.4.0
dotnet test dotnet/xdt/tests -p:XdtVersion=3.1.0
python3 dotnet/xdt/make-custom-xdt.py dotnet/content/applicationHost.xdt dotnet/content/applicationHost.custom.xdt
bash dotnet/xdt/test-preflight.sh
```
