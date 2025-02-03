defmodule StreamerWeb.Socket.Socket do
  use Phoenix.Socket

  channel("radio:*", StreamerWeb.RadioChannel)

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket) do
    nil
  end
end
