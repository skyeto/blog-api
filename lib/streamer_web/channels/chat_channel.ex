defmodule StreamerWeb.ChatChannel do
  use Phoenix.Channel

  alias Streamer.{ChatMessage}

  def join("chat:main", _payload, socket) do
    {:ok,
     %{
       status: :ok,
       nick: gen_nick(),
       messages:
         ChatMessage.get() |> Enum.map(fn msg -> %{nick: msg.nick, content: msg.message} end)
     }, socket}
  end

  def join(_, _, socket) do
    {:error, %{reason: "no such channel"}}
  end

  def handle_in("message", %{"nick" => nick, "content" => msg}, socket) do
    IO.inspect(socket)
    msg = HtmlSanitizeEx.strip_tags(msg)
    nick = HtmlSanitizeEx.strip_tags(nick)

    cond do
      String.length(nick) > 20 ->
        {:reply, {:error, %{reason: "nick too long"}}, socket}

      String.length(msg) > 100 ->
        {:reply, {:error, %{reason: "message too long"}}, socket}

      true ->
        ChatMessage.insert(nick, msg)
        Phoenix.Channel.broadcast(socket, "message", %{nick: nick, content: msg})

        {:reply, :ok, socket}
    end
  end

  defp gen_nick() do
    adjectives = [
      "weird",
      "stinky",
      "badass",
      "rowdy",
      "slippy",
      "tipsy",
      "silly",
      "goofy",
      "killer",
      "top",
      "tiny",
      "eepy",
      "sleepy"
    ]

    animals = [
      "fox",
      "pangolin",
      "penguin",
      "moose",
      "elk",
      "reindeer",
      "dog",
      "goat",
      "cat",
      "cow",
      "aardvark",
      "akita",
      "aardwolf",
      "dhole",
      "alpaca",
      "wolf",
      "axolotl",
      "owl",
      "badger",
      "skunk",
      "bear",
      "lion",
      "panther",
      "corgi",
      "duck",
      "gecko",
      "goose",
      "grouse",
      "hare",
      "rabbit",
      "squirrel",
      "hyena",
      "yeen",
      "crab",
      "deer",
      "koala",
      "kiwi",
      "antelope",
      "llama",
      "lizard",
      "lynx",
      "lemur",
      "mallard",
      "magpie",
      "mink",
      "mouse",
      "newt",
      "ocelot",
      "otter",
      "ox",
      "pelican"
    ]

    prefix = Enum.random(adjectives)
    name = Enum.random(animals)
    ident = Enum.random(1..999) |> Integer.to_string() |> String.pad_leading(3, "0")

    "#{prefix}#{name}#{ident}"
  end
end
