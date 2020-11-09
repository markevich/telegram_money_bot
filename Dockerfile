FROM elixir:1.11.2 as builder

ENV MIX_ENV=prod

RUN mkdir /money_bot
WORKDIR /money_bot

COPY config ./config
COPY lib ./lib
COPY priv ./priv
COPY mix.exs .
COPY mix.lock .

COPY assets/js ./assets/js
COPY assets/css ./assets/css
COPY assets/static ./assets/static
COPY assets/package-lock.json ./assets/package-lock.json
COPY assets/package.json ./assets/package.json
COPY assets/webpack.config.js ./assets/webpack.config.js

RUN apt-get -y update && apt-get -y install build-essential libxtst6 libnss3-dev libxss1 libasound2
RUN curl -sL https://deb.nodesource.com/setup_15.x | bash && apt-get install -y nodejs
RUN mix local.rebar --force \
    && mix local.hex --force \
    && mix deps.get \
    && cd assets && npm install && npm run deploy && cd .. \
    && mix deps.compile \
    && mix phx.digest \
    && mix release
