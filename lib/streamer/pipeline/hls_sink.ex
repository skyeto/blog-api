defmodule Streamer.Pipeline.HLSSink do
  use Membrane.Pipeline

  alias Membrane.HTTPAdaptiveStream.{
    Storages,
    SinkBin,
    Manifest
  }

  def create_output(
        %{hls_storage_module: pid, spec: spec_builder, tracks: tracks_builder} = state
      ) do
    spec =
      spec_builder ++
        [
          child(:hls_sink_bin, %SinkBin{
            manifest_name: "radio",
            manifest_module: Membrane.HTTPAdaptiveStream.HLS,
            storage: %Storages.GenServerStorage{
              destination: pid,
              method: :cast
            },
            target_window_duration: Membrane.Time.seconds(120),
            segment_naming_fun: &segment_naming_fun/1,
            persist?: false,
            mode: :live,
            hls_mode: :separate_av
          }),
          # child(:hls_audio_funnel, Membrane.Funnel)
          child(:hls_audio_funnel, %Membrane.LiveAudioMixer{
            stream_format: %Membrane.RawAudio{
              channels: 2,
              sample_rate: 48_000,
              sample_format: :s16le
            }
          })
          |> child(%Membrane.AAC.FDK.Encoder{
            bitrate: 196_000
          })
          # |> via_in(:input, toilet_capacity: 500)
          # |> child(:aac_parser, %Membrane.AAC.Parser{out_encapsulation: :none})
          |> via_in(Pad.ref(:input, "audio_master"),
            options: [
              encoding: :AAC,
              segment_duration: Membrane.Time.seconds(2)
            ]
          )
          |> get_child(:hls_sink_bin),
          child(:empty_audio_generator, %Membrane.SilenceGenerator{
            stream_format: %Membrane.RawAudio{
              channels: 2,
              sample_rate: 48_000,
              sample_format: :s16le
            },
            duration: :infinity
          })
          |> get_child(:hls_audio_funnel)
          # child(:hls_video_funnel, Membrane.Funnel)
          # |> via_in(Pad.ref(:input, "video_master"),
          #   options: [encoding: :H264, segment_duration: Membrane.Time.seconds(2)]
          # )
          # |> get_child(:hls_sink_bin)
        ]

    tracks =
      tracks_builder ++
        [
          hls_sink: %{audio: get_child(:hls_sink_bin), video: get_child(:hls_sink_bin)}
        ]

    {:ok, %{state | spec: spec, tracks: tracks}}
  end

  @spec segment_naming_fun(Manifest.Track.t()) :: String.t()
  defp segment_naming_fun(track) do
    name = Enum.join([track.content_type, "sgmnt", track.next_segment_id, track.track_name], "_")
    Enum.join([name, Murmur.hash_x86_32(name, 0) |> Integer.to_string(16)], "-")
  end
end
