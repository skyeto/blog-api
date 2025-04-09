defmodule Streamer.Privacypass.RedeemedToken do
  use Ecto.Schema
  import Ecto.Changeset

  alias Streamer.{
    Repo
  }

  alias Streamer.Privacypass.{
    RedeemedToken
  }

  schema "privpass_redeemed_tokens" do
    field(:token, :string)

    timestamps()
  end

  def changeset(token, attrs) do
    token |> cast(attrs, [:token]) |> validate_required([:token])
  end

  def redeem(token) do
    changeset = RedeemedToken.changset(%RedeemedToken{}, %{token: token})
  end
end
