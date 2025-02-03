defmodule Streamer.Application do
  use Application

  def start(_type, _args) do
    rtmp_server_opts = %{
      port: 1935,
      use_ssl?: false,
      listen_options: [
        :binary,
        packet: :raw,
        active: false,
        ip: {0, 0, 0, 0}
      ],
      handle_new_client: &Streamer.Pipeline.RTMP.handle_new_client/3
    }

    children = [
      Streamer.Repo,
      StreamerWeb.Endpoint,
      {Phoenix.PubSub, name: Streamer.PubSub},
      %{
        id: Membrane.RTMPServer,
        start: {Membrane.RTMPServer, :start_link, [rtmp_server_opts]}
      }
    ]

    opts = [strategy: :one_for_one, name: Streamer.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
