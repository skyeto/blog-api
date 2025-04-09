defmodule Streamer.Application do
  require Cachex.Spec
  use Application

  def start(_type, _args) do
    children = [
      Streamer.Repo,
      StreamerWeb.Endpoint,
      {Streamer.Pipeline, name: Streamer.Pipeline},
      {Phoenix.PubSub, name: Streamer.PubSub},
      {Cachex, [:pow_cache, [expiration: Cachex.Spec.expiration(interval: :timer.minutes(3))]]},
      {Streamer.RateLimit, [clean_period: :timer.minutes(1)]}
    ]

    opts = [strategy: :one_for_one, name: Streamer.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
