echo "Setting release and development versions"

# Bump release version if not set
if [ -z "$VERSION" ]; then
    echo "VERSION not set, automatically setting next release version"

    # Fetch current version from nuget and parse version
    CURRENT_RELEASE_VERSION=$(curl "https://api.nuget.org/v3/registration5-semver1/datadog.azureappservices.java.apm/index.json" | jq -r '.items[0]["@id"]' | awk -F '/' '{print $(NF)}')

    # Extract numerical version and increment last value
    RELEASE_VERSION=$(echo "$CURRENT_RELEASE_VERSION" | awk -F '-' '{print $1}' | awk -F '.' '{print $1 "." $2 "." ($3 + 1)}')

    echo "Current release version is ${CURRENT_RELEASE_VERSION}, updating release version to ${RELEASE_VERSION}"
else
    echo "VERSION set, using provided value"
    RELEASE_VERSION=$VERSION
fi

if [ -n "$CI_JOB_ID" ]; then
    echo "CI_JOB_ID is set, using it in the development version"
    DEVELOPMENT_VERSION=$(echo "$RELEASE_VERSION" | awk -F '-' '{print $1}' | awk -v ci_job_id="$CI_JOB_ID" -F '.' '{print $1 "." $2 "." ci_job_id}')
else
    echo "CI_JOB_ID not set, using the release version as the development version"
    DEVELOPMENT_VERSION=$RELEASE_VERSION
fi

DEVELOPMENT_VERSION+="-prerelease"

echo "RELEASE_VERSION=$RELEASE_VERSION"
echo "DEVELOPMENT_VERSION=$DEVELOPMENT_VERSION"

export RELEASE_VERSION=$RELEASE_VERSION
export DEVELOPMENT_VERSION=$DEVELOPMENT_VERSION
