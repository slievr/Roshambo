FROM elixir:1.10.4 as test

WORKDIR /opt/
COPY . .

RUN mix local.rebar --force \
  && mix local.hex --if-missing --force \
  && mix deps.get

ENTRYPOINT ["mix", "test"]
CMD ["mix", "test"]

FROM elixir:1.10.4 as build

WORKDIR /opt
COPY . .

RUN mix local.rebar --force \
  && mix local.hex --if-missing --force \
  && mix deps.get

ARG MIX_ENV=prod
RUN mix compile \
  && mix release

FROM build as iex

WORKDIR /opt/_build/prod/rel/rochambo/bin

CMD ["./rochambo", "start_iex"]

FROM build as prod

WORKDIR /opt/_build/prod/rel/rochambo/bin

CMD ["./rochambo", "start"]
