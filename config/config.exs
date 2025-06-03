import Config

config :streamer, ecto_repos: [Streamer.Repo]
config :membrane_core, :logger, verbose: false

config :streamer, Streamer.Repo,
  database: "streamer",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :ex_aws,
  access_key_id: System.get_env("STREAMER_S3_ACCESS_KEY"),
  secret_access_key: System.get_env("STREAMER_S3_SECRET_ACCESS_KEY")

config :ex_aws, :s3,
  scheme: "https://",
  host: "data.skyeto.net"

config :streamer, StreamerWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "api.blog.skyeto.net", port: 443],
  secret_key_base: System.get_env("STREAMER_SECRET_KEY_BASE"),
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  pubsub_server: Streamer.PubSub

config :streamer, Streamer.Guardian.Session,
  issues: "streamer",
  secret_key: System.get_env("STREAMER_GUARDIAN_SESSION_SECRET")

config :phoenix, :stacktrace_depth, 30
config :logger, :console, format: "[$level] $message\n"
config :phoenix, :plug_init_mode, :runtime
config :tesla, adapter: {Tesla.Adapter.Hackney, recv_timeout: 30_000}
