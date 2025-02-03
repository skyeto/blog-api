defmodule StreamerWeb.RadioChannel do
  use Phoenix.Channel

  def join("radio:status", _payload, socket) do
    status =
      try do
        GenServer.call({:global, :audio_master_storage}, :get_stream_status)
      catch
        _, _ -> :offline
      end

    {:ok, status, socket}
  end

  def join(_, _, socket) do
    {:error, %{reason: "no such channel"}}
  end
end
