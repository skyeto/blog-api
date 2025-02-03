import Config

config :streamer, ecto_repos: [Streamer.Repo]

config :streamer, Streamer.Repo,
  database: "streamer",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :ex_aws,
  access_key_id: "bZ9cytNfaIwlF1vANaNK",
  secret_access_key: "RgzQ28cHbxJsnDH8RifB8zSUvXxxItgLM0Apdi8B"

config :ex_aws, :s3,
  scheme: "https://",
  host: "data.skyeto.net"

config :streamer, StreamerWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "api.blog.skyeto.net", port: 443],
  secret_key_base: "bBLH8/x1osO617ev7XKMpqSss3MsdZvopqJPlU8CmYmZa1J0YVTNFaJUcPtGdKeb",
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  pubsub_server: Streamer.PubSub

config :phoenix, :stacktrace_depth, 30
config :logger, :console, format: "[$level] $message\n"
config :phoenix, :plug_init_mode, :runtime
