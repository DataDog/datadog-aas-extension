
 param (
    [Parameter(Mandatory=$true)][string]$subscriptionId,
    [Parameter(Mandatory=$true)][string]$appId,
    [Parameter(Mandatory=$true)][string]$appName,
    [Parameter(Mandatory=$true)][string]$tenantId,
    [Parameter(Mandatory=$true)][string]$password
 )

# https://mauridb.medium.com/calling-azure-rest-api-via-curl-eb10a06127

# Create principal
az ad sp create-for-rbac --name ${appName} --password ${password}

echo ${subscriptionId} >> .\${appName}\subscriptionId.txt
echo ${tenantId} >> .\${appName}\tenantId.txt
echo ${appId} >> .\${appName}\appId.txt

# Request token
curl -X POST -d 'grant_type=client_credentials&client_id=${appId}&client_secret=${password}&resource=https%3A%2F%2Fmanagement.azure.com%2F' https://login.microsoftonline.com/${tenantId}/oauth2/token >> .\${appName}\service-principal-token.txt

# If you lose your token or other information, find it with this command:
#
# az account list --output table --query '[].{Name:${appName}, SubscriptionId:${subscriptionId}, TenantId:${tenantId}}'
#

# Get your appId from the following command:
#
# az ad sp list
# 

# Your authorization token should look something like this:
#
# eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImlCakwxUmNxemhpeTRmcHhJeGRacW9oTTJZayIsImtpZCI6ImlCakwxUmNxemhpeTRmcHhJeGRac
# [...]
# hkSFwruPWvkE15zzleYir_SsSVveaRlMUq9q7GOEr87aGvOVB3QManIn_jIo1cnDCUJZ3WX7hcMvq0dLE8Ap1ZL_HQqOzLbJfpnSCDfs2X2pBmqB3JH5rzrCAzeL1mYL5TOgC8k3s1Z_vvTqxD2XrO7QOGhGfxqxxDWJAXiblUtafHg
#