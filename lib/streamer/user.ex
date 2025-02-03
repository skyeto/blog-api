defmodule Streamer.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Streamer.{
    Repo,
    User
  }

  schema "users" do
    field(:username, :string)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
  end
end
