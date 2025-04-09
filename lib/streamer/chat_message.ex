defmodule Streamer.ChatMessage do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Streamer.{ChatMessage, Repo}

  schema "chat_messages" do
    field(:nick, :string)
    field(:message, :string)

    timestamps()
  end

  def changeset(message, attrs) do
    message |> cast(attrs, [:nick, :message]) |> validate_required([:nick, :message])
  end

  def insert(nick, message) do
    changeset = changeset(%ChatMessage{}, %{nick: nick, message: message})

    Repo.insert(changeset)
  end

  def get(latest \\ :all) do
    case latest do
      :all ->
        Repo.all(ChatMessage)
    end
  end
end
