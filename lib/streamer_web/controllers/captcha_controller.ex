defmodule StreamerWeb.CaptchaController do
  use StreamerWeb, :controller

  def get_challenge(conn, _params) do
    {:ok, chall} = Streamer.Pow.generate()
    conn |> text(chall)
  end

  def get_ticket(conn, %{"solution" => solution}) do
    json(conn, %{status: Streamer.Pow.verify_solution(solution)})
  end
end
