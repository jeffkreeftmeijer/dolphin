FROM node as ASSET_BUILD
COPY assets assets
WORKDIR assets
RUN npm install

FROM elixir
COPY --from=ASSET_BUILD assets assets
RUN mix local.hex --force
RUN mix local.rebar --force
COPY mix.exs .
COPY mix.lock .
RUN mix deps.get
COPY . .

ENV MIX_ENV prod
CMD ["elixir", "-S", "mix", "phx.server"]
