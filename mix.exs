defmodule Streamer.MixProject do
  use Mix.Project

  def project do
    [
      app: :streamer,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Streamer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Web
      {:bandit, "~> 1.6"},
      {:plug, "~> 1.16"},
      {:hackney, "~> 1.9"},
      {:phoenix, "~> 1.7"},
      {:corsica, "~> 2.1"},
      {:phoenix_pubsub, "~> 2.1"},
      {:html_sanitize_ex, "~> 1.4"},
      {:tesla, "~> 1.14"},
      {:mint, "~> 1.7"},
      {:jason, "~> 1.4"},
      {:guardian, "~> 2.3"},
      {:guardian_phoenix, "~> 2.0"},
      {:jose, "~> 1.11"},

      # AV
      {:membrane_core, "~> 1.1"},
      {:membrane_opus_plugin, "~> 0.20.4"},
      # {:membrane_webrtc_plugin, "~> 0.23.0"},
      {:membrane_portaudio_plugin, "~> 0.19.2"},
      {:membrane_rtmp_plugin, "~> 0.27.3"},
      {:membrane_matroska_plugin, "~> 0.6.0"},
      {:membrane_fake_plugin, "~> 0.11.0"},
      {:membrane_http_adaptive_stream_plugin, "~> 0.18.6"},
      {:membrane_aac_plugin, "~> 0.19.0"},
      {:membrane_aac_fdk_plugin, "~> 0.18.11"},
      {:membrane_audio_mix_plugin, "~> 0.16.2"},
      {:membrane_ffmpeg_swresample_plugin, "~> 0.20.2"},
      {:membrane_mp4_plugin, "~> 0.35.2"},

      # DB
      {:ecto, "~> 3.12"},
      {:phoenix_ecto, "~> 4.6"},
      {:ecto_sql, "~> 3.12"},
      {:postgrex, "~> 0.19.3"},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:cachex, "~> 4.0"},

      # Extra
      {:sweet_xml, "~> 0.6"},
      {:blake2_elixir, "~> 0.8.1"},
      {:murmur, "~> 2.0"},
      {:hammer, "~> 7.0"}
    ]
  end
end
