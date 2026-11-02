# One-step applicationHost.xdt for the .NET extension

App Service applies every site extension's `applicationHost.xdt` in one run each time a worker starts. If that run takes more than about 60 seconds, App Service drops every extension's changes. It logs no error and doesn't retry, so the worker starts without the tracer. The classic file (`../content/applicationHost.xdt`) needs 68 XDT operations, and on a busy instance that can take more than 60 seconds.

This folder holds a custom XDT transform that sets the same variables in one operation.

- `src/`: `SetEnvironmentVariables`, a `Microsoft.Web.XmlTransform.Transform`, built for .NET Framework 4.5 against `Microsoft.Web.XmlTransform` 1.4.0.0, the version in the App Service GAC. It never logs an error and never throws. On any problem it logs a warning and leaves the config unchanged, so other extensions keep their settings.
- `make-custom-xdt.py`: generates `../content/applicationHost.custom.xdt` from the classic file. Rerun it whenever the classic file changes; a test fails if they drift.
- `../content/preflight.ps1`: called by `install.ps1` in Kudu at install time. It installs the one-step file only if this instance can load the DLL and the dry run gives the same variables as the classic file. Otherwise it keeps the classic file.
- `tests/`: unit tests, run against engines 1.4.0 and 3.1.0. `test-preflight.sh` checks the preflight's decisions locally under `pwsh`.

```sh
dotnet build -c Release dotnet/xdt/src
dotnet test dotnet/xdt/tests -p:XdtVersion=1.4.0
dotnet test dotnet/xdt/tests -p:XdtVersion=3.1.0
python3 dotnet/xdt/make-custom-xdt.py dotnet/content/applicationHost.xdt dotnet/content/applicationHost.custom.xdt
bash dotnet/xdt/test-preflight.sh
```
