defmodule Streamer.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages) do
      add(:message, :string)
      add(:nick, :string)

      timestamps()
    end
  end
end
