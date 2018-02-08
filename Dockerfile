FROM elixir:1.5.3

ENV TZ Europe/Helsinki
WORKDIR /usr/src/app
COPY . /usr/src/app

ARG secret_key_base

ENV MIX_ENV=prod
ENV PORT=8000
ENV SECRET_KEY_BASE=${secret_key_base}

RUN mix local.hex --force
RUN mix local.rebar
RUN mix deps.get
RUN mix compile
RUN mix phx.digest

EXPOSE 8000
CMD [ "mix", "phx.server" ]
