# This file only for test purposes in development
# Run it on the instance to replace the existing config
rm /home/datadog/datadog.yaml
touch /home/datadog/datadog.yaml
echo '## disable sending the host metadata payload' >>/home/datadog/datadog.yaml
echo 'enable_metadata_collection: false' >>/home/datadog/datadog.yaml
echo 'apm_config:' >>/home/datadog/datadog.yaml
echo '  enabled: true' >>/home/datadog/datadog.yaml
echo '  log_file: /home/LogFiles/datadog/trace-log.txt' >>/home/datadog/datadog.yaml
echo '## log_level: debug' >>/home/datadog/datadog.yaml
echo 'cloud_provider_metadata:' >>/home/datadog/datadog.yaml
echo '  - 'azure'' >>/home/datadog/datadog.yaml
echo '' >>/home/datadog/datadog.yaml