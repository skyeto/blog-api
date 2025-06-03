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

    ollama = Ollama.init(Application.get_env(:streamer, :ollama_api))

    {rate_limit_resp, window} =
      Streamer.RateLimit.hit(
        "chat_send:#{socket.assigns.guardian_default_claims["sub"]}",
        :timer.minutes(1),
        5
      )

    cond do
      rate_limit_resp == :deny ->
        {:reply, {:error, %{reason: "rate_limit", details: Integer.to_string(div(window, 1000))}},
         socket}

      String.equivalent?(nick, "system") ->
        {:reply, {:error, %{reason: "bad_nick", details: "nick cannot be system"}}, socket}

      String.length(nick) > 20 ->
        {:reply, {:error, %{reason: "nick_too_long", details: "nick too long"}}, socket}

      String.length(msg) > 100 ->
        {:reply, {:error, %{reason: "long_message", details: "message too long"}}, socket}

      true ->
        # TODO: Probably best to always broadcast, but then clear it if the content ends up bad...
        Phoenix.Channel.broadcast(socket, "message", %{nick: nick, content: msg})

        {:ok, %{"response" => check_resp}} =
          Ollama.completion(ollama, model: "llama-guard3:1b", prompt: msg)

        if String.contains?(check_resp, "unsafe") do
          type =
            case String.split(check_resp, "\n") |> Enum.at(1) do
              "S12" -> "woah thirsty are we"
              "S10" -> "hate speech!? this incident will be reported"
              t -> "generic"
            end

          {:reply, {:error, %{reason: "unsafe_message", details: type}}, socket}
        else
          ChatMessage.insert(nick, msg)
          {:reply, :ok, socket}
        end
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
