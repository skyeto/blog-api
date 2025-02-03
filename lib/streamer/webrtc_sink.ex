defmodule Streamer.WebRTCSource do
  use Membrane.Pipeline

  alias Membrane.WebRTC

  @impl true
  def handle_init(_context, signaling) do
    spec =
      [
        child(:webrtc, %Membrane.WebRTC.Source{
          signaling: signaling,
          allowed_video_codecs: :h264
        }),
        get_child(:webrtc)
        |> via_out(:output, options: [kind: :audio])
        |> child(:parsed_audio, Membrane.Opus.Parser)
        |> child(:decoded_audio, Membrane.Opus.Decoder),
        get_child(:webrtc)
        |> via_out(:output, options: [kind: :video])
        |> child(Membrane.Fake.Sink.Buffers),
        get_child(:decoded_audio)
        |> child(:encoded, %Membrane.AAC.FDK.Encoder{})
        |> child(%Membrane.AAC.Parser{out_encapsulation: :none})
        |> via_in(Pad.ref(:input, :audio),
          options: [encoding: :AAC, segment_duration: Membrane.Time.seconds(1)]
        )
        |> child(%Membrane.HTTPAdaptiveStream.SinkBin{
          manifest_name: "manifest",
          manifest_module: Membrane.HTTPAdaptiveStream.HLS,
          storage: %Membrane.HTTPAdaptiveStream.Storages.FileStorage{
            directory: "output"
          },
          target_window_duration: Membrane.Time.seconds(40),
          persist?: false,
          mode: :live,
          hls_mode: :separate_av
        })
        |> child(Membrane.AAC.FDK.Decoder)
        |> child(Membrane.PortAudio.Sink)
        # |> child(%Membrane.HTTPAdaptiveStream.Sink{
        #   track_config: %Membrane.HTTPAdaptiveStream.Sink.TrackConfig{
        #     mode: :live,
        #     persist?: false,
        #     segment_duration: Membrane.Time.seconds(2),
        #     target_window_duration: Membrane.Time.seconds(6)
        #   },
        #   manifest_config: %Membrane.HTTPAdaptiveStream.Sink.ManifestConfig{
        #     name: "manifest",
        #     module: Membrane.HTTPAdaptiveStream.HLS
        #   },
        #   storage: %Membrane.HTTPAdaptiveStream.Storages.FileStorage{
        #     directory: "output"
        #   }
        # })
      ]

    {[spec: spec], %{}}
  end

  @impl true
  def handle_element_end_of_stream(:sink, :input, _ctx, state) do
    {[terminate: :normal], state}
  end

  @impl true
  def handle_element_end_of_stream(_element, _pad, _ctx, state) do
    {[], state}
  end
end
