FROM elixir:1.5.1-slim
MAINTAINER Team Aegis <aegis@decisiv.com>

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && apt-get install -y --no-install-recommends apt-utils build-essential
RUN mkdir /app
WORKDIR /app
ADD . /app

RUN mix do local.hex --force, local.rebar -force, deps.get

ENTRYPOINT ["mix"]
CMD ["do" "compile", "test"]
