 
# Per site, you can use the username and password from the publish profile you download.
# The recommended approach is to use a service account which has permission to access Kudu
# Note that the $username here should look like `SomeUserName`, and **not** `SomeSite\SomeUserName`
 param (
    [Parameter(Mandatory=$true)][string]$sitename,
    [Parameter(Mandatory=$true)][string]$username,
    [Parameter(Mandatory=$true)][string]$password,
    [Parameter(Mandatory=$false)][Switch]$InstallLatest,
    [Parameter(Mandatory=$false)][Switch]$Remove,
    [Parameter(Mandatory=$false)][string]$extension="Datadog.AzureAppServices"
 )


if ($InstallLatest -eq $true -and $Remove -eq $true) {
  throw "You must specify only one of -InstallLatest and -Remove"
}

# 
# Example call of this script:
# .\install-latest-site-extension.ps1 -sitename $sitename -username $username -password $password -InstallLatest
#
# Manually specifying the extension id:
# .\install-latest-site-extension.ps1 -sitename $sitename -username $username -password $password -extension "Datadog.Development.AzureAppServices" -InstallLatest
#
# Removing the extension:
# .\install-latest-site-extension.ps1 -sitename $sitename -username $username -password $password -Remove
#

# # Example 1: call the zip controller API (which uses PUT)
# $apiUrl = "${baseApiUrl}zip/site/wwwroot/"
# $filePath = "C:\Temp\books.zip"
# Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method PUT -InFile $filePath -ContentType "multipart/form-data"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
