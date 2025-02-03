defmodule Streamer.Router do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  forward(
    "/whip",
    to: Membrane.WebRTC.WhipServer.Router,
    handle_new_client: &__MODULE__.handle_new_client/1
  )

  def handle_new_client(token) do
    signaling = Membrane.WebRTC.SignalingChannel.new()

    IO.inspect(token)
    {:ok, sup, _pipeline} = Membrane.Pipeline.start_link(Streamer.WebRTCSource, signaling)
    Process.monitor(sup)

    {:ok, signaling}
  end
end
