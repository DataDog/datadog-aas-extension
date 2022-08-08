FROM mcr.microsoft.com/dotnet/core/sdk:3.1
RUN apt-get update
RUN apt-get install unzip
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs
RUN mkdir -p release && export CI_PROJECT_DIR="release"
ENV CI_PROJECT_DIR=/home/datadog-aas-extension
COPY . /home/datadog-aas-extension
WORKDIR /home/datadog-aas-extension
RUN mkdir output
RUN ./node/build-packages.sh