 
# Per site, you can use the username and password from the publish profile you download.
# The recommended approach is to use a service account which has permission to access Kudu
# Note that the $username here should look like `SomeUserName`, and **not** `SomeSite\SomeUserName`

 param (
    [Parameter(Mandatory=$true)][string]$siteName,
    [Parameter(Mandatory=$true)][string]$username,
    [Parameter(Mandatory=$true)][string]$password,
    [Parameter(Mandatory=$true)][string]$extension,
    [Parameter(Mandatory=$false)][Switch]$InstallLatest,
    [Parameter(Mandatory=$false)][Switch]$Remove
 )

if ($InstallLatest -eq $true -and $Remove -eq $true) {
  throw "You must specify only one of -InstallLatest and -Remove"
}

# 
# Example call of this script:
# .\manage-site-extension.ps1 -siteName $siteName -username $username -password $password -extension "Datadog.AzureAppServices.DotNet" -InstallLatest
#
# Manually specifying the extension id:
# .\manage-site-extension.ps1 -siteName $siteName -username $username -password $password -extension "Datadog.AzureAppServices.DotNet" -InstallLatest
#
# Removing the extension:
# .\manage-site-extension.ps1 -siteName $siteName -username $username -password $password -extension "Datadog.AzureAppServices.DotNet" -Remove
#

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$baseApiUrl = "https://${siteName}.scm.azurewebsites.net/api"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
$userAgent = "powershell/1.0"

$siteExtensionsBase="${baseApiUrl}/siteextensions"

$siteExtensionManage="${baseApiUrl}/siteextensions/${extension}"

# GET EXTENSION INFO, ERROR IF NOT PRESENT
# Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method GET

if ($InstallLatest) {
  # INSTALL OR UPDATE TO LATEST
  Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method PUT
  Write-Output "Completed request to install latest of ${extension} to ${siteName}"
}
elseif ($Remove) {
  # INSTALL OR UPDATE TO LATEST
  Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method DELETE
  Write-Output "Completed request to remove ${extension} from ${siteName}"
}
