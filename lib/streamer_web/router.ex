defmodule StreamerWeb.Router do
  use StreamerWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])

    plug(CORSPlug,
      origin: [
        "http://localhost:4321",
        "https://skyeto.com",
        "https://blogtesting.skyeto.net",
        "https://hlsjs-dev.video-dev.org",
        "https://bitmovin.com",
        "*"
      ]
    )
  end

  scope "/api" do
    pipe_through(:api)

    options("/license", StreamerWeb.LicenseController, :options)
    get("/license", StreamerWeb.LicenseController, :license)

    get("/pow", StreamerWeb.CaptchaController, :get_challenge)
    post("/pow", StreamerWeb.CaptchaController, :get_ticket)
  end
end
