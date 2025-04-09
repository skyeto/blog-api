defmodule StreamerWeb.Socket.Socket do
  use Phoenix.Socket

  channel("radio:*", StreamerWeb.RadioChannel)
  channel("chat:*", StreamerWeb.ChatChannel)

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Guardian.Phoenix.Socket.authenticate(socket, Streamer.Guardian.Session, token) do
      {:ok, authed_socket} ->
        {:ok, authed_socket}

      {:error, _} ->
        :error
    end
  end

  def connect(_params, _socket, _info) do
    :error
  end

  @impl true
  def id(_socket) do
    nil
  end
end
