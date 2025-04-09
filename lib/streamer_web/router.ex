defmodule StreamerWeb.Router do
  use StreamerWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :token_auth do
    plug(Guardian.Plug.VerifyHeader)
    plug(Guardian.Plug.EnsureAuthenticated)
  end

  scope "/api" do
    pipe_through(:api)

    get("/license", StreamerWeb.LicenseController, :license)

    get("/pow", StreamerWeb.CaptchaController, :get_challenge)
    post("/pow", StreamerWeb.CaptchaController, :get_ticket)

    get("/token-challenge", StreamerWeb.PrivacyPassController, :token_challenge)
    post("/token-request", StreamerWeb.PrivacyPassController, :token_request)
    post("/token-exchange", StreamerWeb.PrivacyPassController, :token_exchange)
  end

  scope "/" do
    pipe_through(:token_auth)
  end
end
