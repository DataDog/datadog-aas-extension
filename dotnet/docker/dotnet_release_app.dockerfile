FROM mcr.microsoft.com/dotnet/sdk:8.0-bookworm-slim AS build_app

RUN set -x \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends  openssh-client

RUN set -x \
    && git clone https://github.com/DataDog/dotnet-aas-samples.git \
    && cd dotnet-aas-samples/Junkyard.Web \
    && dotnet publish -c Release --framework net8.0 -o /app

FROM mcr.microsoft.com/dotnet/sdk:8.0-bookworm-slim AS setup_apm

ARG APM_COMMIT_SHA

ARG ARTIFACT_NAME="datadog-dotnet-apm.tar.gz"

RUN set -x \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends  xq

# Retrieve and install .NET APM
RUN set -x \
    && curl -sS https://apmdotnetci.blob.core.windows.net/apm-dotnet-ci-artifacts-master/\?comp\=list\&prefix\=${APM_COMMIT_SHA} |  xq -x EnumerationResults/Blobs/Blob/Url | grep -E 'datadog-dotnet-apm-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz' | xargs curl -sSL -o ${ARTIFACT_NAME} \
    && mkdir -p /opt/datadog \
    && tar zxvf ${ARTIFACT_NAME} -C /opt/datadog

# final stage/image
FROM mcr.microsoft.com/dotnet/aspnet:8.0-bookworm-slim

ARG APM_COMMIT_SHA

# setup SSH for debugging/investigation (in Azure portal)
RUN set -x \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssh-server

RUN echo "root:Docker!" | chpasswd
RUN ssh-keygen -A

COPY sshd_config /etc/ssh/

WORKDIR /app

COPY --from=datadog/serverless-init:1 /datadog-init /app/datadog-init

COPY --from=build_app /app .
COPY --from=setup_apm /opt /opt

# setup logs folder
RUN set -x \
    && chmod +x /opt/datadog/createLogPath.sh \
    && /opt/datadog/createLogPath.sh

## Common Environment variables set here.
## Enabling the CLR Profiler, DD Tracer, DD Profiler will be done from the app settings to allow
## flexibility while creating different applications
ENV CORECLR_PROFILER={846F5F1C-F9AE-4B07-969E-05C26BC060D8}
ENV CORECLR_PROFILER_PATH=/opt/datadog/Datadog.Trace.ClrProfiler.Native.so
ENV DD_DOTNET_TRACER_HOME=/opt/datadog
ENV LD_PRELOAD=/opt/datadog/linux-x64/Datadog.Linux.ApiWrapper.x64.so
ENV DD_VERSION="master-${APM_COMMIT_SHA}"

ENV PORT 8080
# expose 2222 for SSH
EXPOSE 8080 2222

ENV ASPNETCORE_URLS "http://*:${PORT}"

ENTRYPOINT ["/app/datadog-init"]

CMD ["bash", "-c", "service ssh start && /app/Junkyard.Web"]
