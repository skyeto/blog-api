defmodule Streamer.Guardian.Session do
  use Guardian, otp_app: :streamer

  def subject_for_token(%{id: id}, _claims) do
    sub = to_string(id)

    {:ok, sub}
  end

  def subject_for_token(_, _) do
    {:error, :omgwtf}
  end

  def resource_from_claims(%{"sub" => sub}) do
    {:ok, sub}
  end

  def resource_from_clains(_) do
    {:error, :omgwtfbbq}
  end
end
