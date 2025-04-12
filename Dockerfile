FROM hexpm/elixir:1.17.2-erlang-27.0.1-debian-bullseye-20240904-slim AS builder

RUN apt-get update -y && apt-get install -y build-essential git openssl libssl-dev pkg-config \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV="prod"

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

COPY config/runtime.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib

RUN mix compile

COPY rel rel
RUN mix release

FROM debian:bullseye-20240904-slim

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libssl-dev libncurses5 locales ca-certificates libsrtp2-dev && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app
RUN chown nobody /app

ENV MIX_ENV="prod"

COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/streamer ./

USER nobody

CMD ["sh", "-c", "/app/bin/streamer eval \"Streamer.Release.migrate\" && /app/bin/streamer start --no-halt"]
