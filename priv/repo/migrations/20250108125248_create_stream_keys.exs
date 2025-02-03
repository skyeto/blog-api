defmodule Streamer.Repo.Migrations.CreateStreamKeys do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:username, :string)
    end

    create table(:stream_keys) do
      add(:key, :string)

      add(:user_id, references(:users))
    end
  end
end
