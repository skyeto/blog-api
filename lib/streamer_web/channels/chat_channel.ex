defmodule StreamerWeb.ChatChannel do
  use Phoenix.Channel

  def join("chat:main", _payload, socket) do
    {:ok, [], socket}
  end

  def join(_, _, socket) do
    {:error, %{reason: "no such channel"}}
  end

  def handle_in("message", %{"content" => msg}, socket) do
    msg = HtmlSanitizeEx.strip_tags(msg)
    Phoenix.Channel.broadcast(socket, "message", %{user: "skye", content: msg})
    {:reply, :ok, socket}
  end
end
