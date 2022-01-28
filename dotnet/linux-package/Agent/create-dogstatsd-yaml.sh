# This file only for test purposes in development
# Run it on the instance to replace the existing config
rm datadog.yaml
touch datadog.yaml
echo '## disable sending the host metadata payload' >>datadog.yaml
echo 'enable_metadata_collection: false' >>datadog.yaml
echo 'use_dogstatsd: true' >>datadog.yaml
echo 'log_file: /home/LogFiles/datadog/dogstatsd.txt' >>datadog.yaml
echo '## log_level: debug' >>datadog.yaml
echo 'cloud_provider_metadata:' >>datadog.yaml
echo '  - 'azure'' >>datadog.yaml
echo '' >>datadog.yaml