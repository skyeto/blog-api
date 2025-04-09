defmodule StreamerWeb.PrivacyPassController do
  use StreamerWeb, :controller

  def token_challenge(conn, _params) do
    ppChallenge =
      Tesla.get!("http://localhost:3000/token-challenge").body

    {:ok, powChallenge} = Streamer.Pow.generate()

    conn
    |> json(%{
      ppChallenge: ppChallenge,
      powChallenge: powChallenge
    })
  rescue
    e -> json(conn, %{status: "error", reason: :challenge_server_down})
  end

  def token_request(
        conn,
        %{"powSolution" => powResponse, "ppTokenRequest" => tokenRequest} = _params
      ) do
    case Streamer.Pow.verify_solution(powResponse) do
      :ok ->
        tokens =
          Tesla.post!(
            "http://localhost:3000/token-request",
            Jason.encode!(%{tokenRequest: tokenRequest}),
            opts: [adapter: [recv_timeout: 5_000]]
          ).body

        json(conn, %{status: "ok", token: tokens})

      {:error, reason} ->
        json(conn, %{status: "error", reason: reason})
    end
  end

  def token_exchange(conn, %{"token" => token}) do
    isValid =
      Tesla.post!("http://localhost:3000/token-validate", Jason.encode!(%{token: token})).body

    case isValid do
      "valid" ->
        {:ok, sessionToken, _} =
          Streamer.Guardian.Session.encode_and_sign(%{id: "anyonymous"}, %{}, ttl: {24, :hours})

        json(conn, %{valid: isValid, session_token: sessionToken})

      "invalid" ->
        json(conn, %{error: "invalid", valid: false})

      _ ->
        json(conn, %{error: "invalid", valid: false})
    end
  end

  defp issueToken(tokenChallenge) do
    Tesla.post!("http://localhost:3000/token-request", tokenChallenge).body
  end
end
