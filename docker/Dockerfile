FROM ubuntu:20.04

ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get upgrade -y && apt-get install -y curl
RUN curl -fsSL https://crystal-lang.org/install.sh | bash -s -- --version=1.1
RUN apt-get install -y git libssl-dev
RUN mkdir -p /code

CMD tail -f /dev/null
