defmodule Streamer.Repo.Migrations.CreatePrivacyPassCache do
  use Ecto.Migration

  def change do
    create table(:privpass_redeemed_tokens) do
      add(:token, :string)

      timestamps()
    end
  end
end
