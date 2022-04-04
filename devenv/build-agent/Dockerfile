FROM ubuntu:focal
RUN apt-get update && apt-get upgrade -y
RUN apt-get install software-properties-common curl gnupg2 lsb-release -y
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN curl -sSL https://get.docker.com/ | sh
RUN apt-get update && apt-get install nomad -y
ENV NOMAD_DISABLE_PERM_MGMT=true
CMD nomad agent -dev -bind 0.0.0.0 -log-level INFO
