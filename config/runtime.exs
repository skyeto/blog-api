import Config

config :streamer,
  ecto_repos: [Streamer.Repo],
  privpass_api: System.get_env("STREAMER_PRIVPASS_API", "http://localhost:3000"),
  ollama_api: System.get_env("STREAMER_OLLAMA_API", "http://localhost:11434/api")

config :streamer, Streamer.Repo,
  database: System.get_env("STREAMER_DB_NAME") || "streamer",
  username: System.get_env("STREAMER_DB_USERNAME") || "postgres",
  password: System.get_env("STREAMER_DB_PASSWORD") || "postgres",
  hostname: System.get_env("STREAMER_DB_HOST") || "localhost"

config :ex_aws,
  access_key_id: System.get_env("STREAMER_S3_ACCESS_KEY"),
  secret_access_key: System.get_env("STREAMER_S3_SECRET_ACCESS_KEY")

config :ex_aws, :s3,
  scheme: "https://",
  host: "data.skyeto.net"

config :streamer, StreamerWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "blog-api.skyeto.net", port: 3000],
  secret_key_base: System.get_env("STREAMER_SECRET_KEY_BASE"),
  http: [port: 3000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  pubsub_server: Streamer.PubSub

if System.get_env("PHX_SERVER") do
  config :streamer, StreamerWeb.Endpoint, server: true
end

config :streamer, Streamer.Guardian.Session,
  issues: "streamer",
  secret_key: System.get_env("STREAMER_GUARDIAN_SESSION_SECRET")
