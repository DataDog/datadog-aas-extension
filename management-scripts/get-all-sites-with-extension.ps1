 
# Per site, you can use the username and password from the publish profile you download.
# The recommended approach is to use a service account which has permission to access Kudu
# Note that the $username here should look like `SomeUserName`, and **not** `SomeSite\SomeUserName`
 param (
    [Parameter(Mandatory=$true)][string]$username,
    [Parameter(Mandatory=$true)][string]$password,
    [Parameter(Mandatory=$false)][string]$extension="Datadog.AzureAppServices"
 )

# 
# Example call of this script:
# .\get-all-sites-with-extension.ps1 -username $username -password $password
#

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$allSites=& 'az webapps list'

$baseApiUrl = "https://${sitename}.scm.azurewebsites.net/api"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
$userAgent = "powershell/1.0"

$siteExtensionsBase="${baseApiUrl}/siteextensions"

$siteExtensionManage="${baseApiUrl}/siteextensions/${extension}"

# GET EXTENSION INFO, ERROR IF NOT PRESENT
# Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method GET

if ($InstallLatest) {
  # INSTALL OR UPDATE TO LATEST
  Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method PUT
  Write-Output "Completed request to install latest of ${extension} to ${sitename}"
}
elseif ($Remove) {
  # INSTALL OR UPDATE TO LATEST
  Invoke-RestMethod -Uri $siteExtensionManage -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method DELETE
  Write-Output "Completed request to remove ${extension} from ${sitename}"
}
