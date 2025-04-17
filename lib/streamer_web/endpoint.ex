defmodule StreamerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :streamer

  socket("/socket", StreamerWeb.Socket.Socket,
    websocket: true,
    longpoll: false
  )

  plug(Corsica,
    origins: [
      "http://localhost:4321",
      "https://skyeto.com",
      "https://staging.blog.skyeto.net",
      "https://api.blog.skyeto.net"
    ],
    allow_methods: :all,
    allow_headers: :all
  )

  if code_reloading? do
    plug(Phoenix.CodeReloader)
    plug(Phoenix.Ecto.CheckRepoStatus, otp_app: :streamer)
  end

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, store: :cookie, key: "_skyeto_streamer_key", signing_salt: "ne8@dZ9")

  plug(StreamerWeb.Router)
end
