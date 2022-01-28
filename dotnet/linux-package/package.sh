apt-get update
apt-get install binutils -y

mkdir dotnet-debian-temp
mkdir dotnet-debian-temp/agent
mkdir dotnet-debian-temp/dogstatsd
mkdir dotnet-debian-temp/tracer
mkdir dotnet-debian
mkdir dotnet-debian/dotnet-tracer

cwd=$(pwd)

echo "Downloading datadog-agent.deb"
curl -L https://s3.amazonaws.com/apt.datadoghq.com/pool/d/da/datadog-agent_7.32.4-1_amd64.deb -o dotnet-debian-temp/agent/datadog-agent.deb

echo "Changing to agent download directory"
cd dotnet-debian-temp/agent

echo "Unpacking agent"
ar -x datadog-agent.deb

echo "Extracting agent"
tar -xf data.tar.gz

echo "Isolating trace agent"
mv opt/datadog-agent/embedded/bin/trace-agent dotnet-debian/trace-agent

echo "Resetting working directory"
cd $cwd

echo "Downloading dogstatsd"
curl -L https://s3.amazonaws.com/apt.datadoghq.com/pool/d/da/datadog-dogstatsd_7.32.4-1_amd64.deb -o dotnet-debian-temp/dogstatsd/dogstatsd.deb

echo "Changing to dogstatsd directory"
cd dotnet-debian-temp/dogstatsd

echo "Unpacking dogstatsd"
ar -x dogstatsd.deb

echo "Extracting dogstatsd"
tar -xf data.tar.gz 

echo "Isolating dogstatsd"
mv opt/datadog-dogstatsd/bin/dogstatsd dotnet-debian/dogstatsd

echo "Resetting working directory"
cd $cwd

echo "Downloading tracer"
curl -L https://github.com/DataDog/dd-trace-dotnet/releases/download/v2.1.1/datadog-dotnet-apm_2.1.1_arm64.deb -o dotnet-debian-temp/tracer/dotnet-tracer.deb

echo "Changing to temp directory"
cd dotnet-debian-temp/tracer

echo "Unpacking tracer"
ar -x dotnet-tracer.deb

echo "Extracting tracer"
tar -xf data.tar.gz

echo "Isolate tracer binaries next to agent files"
mv opt/datadog/* $(cwd)/dotnet-debian/dotnet-tracer

echo "Resetting working directory"
cd $cwd

echo "Remove extra temp files"
rm -r dotnet-debian-temp

echo "Copy config yaml"
cp -r dotnet/linux-package/Agent/. dotnet-debian

echo "Compressing package"
tar -czvf datadog-dotnet-debian-aas.tar.gz dotnet-debian
pwd; ls
echo "Moving package"
mkdir $CI_PROJECT_DIR/dotnet-debian-package
mv datadog-dotnet-debian-aas.tar.gz $CI_PROJECT_DIR/dotnet-debian-package

