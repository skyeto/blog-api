defmodule StreamerWeb.LicenseController do
  use StreamerWeb, :controller

  def license(conn, params) do
    key =
      try do
        GenServer.call({:global, :audio_master_storage}, :get_crypto)
      catch
        _, _ -> conn |> text("stream offline") |> halt()
      end

    conn
    |> put_resp_content_type("application/pgp-keys", "binary")
    |> send_download({:binary, key.key}, filename: "key", encode: false)
  end
end
