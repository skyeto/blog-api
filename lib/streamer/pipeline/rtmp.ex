defmodule Streamer.Pipeline.RTMP do
  use Membrane.Pipeline

  alias Membrane.HTTPAdaptiveStream.{
    SinkBin,
    Manifest,
    HLS,
    Storages
  }

  def create_input(%{spec: spec_builder, tracks: tracks_builder} = state, client_ref) do
    spec =
      spec_builder ++
        [
          child(:rtmp_source, %Membrane.RTMP.SourceBin{client_ref: client_ref})
        ]

    tracks =
      tracks_builder ++
        [
          rtmp_source: %{
            audio:
              get_child(:rtmp_source)
              |> via_out(:audio)
              |> child(:aac_decoder, Membrane.AAC.FDK.Decoder),
            video:
              get_child(:rtmp_source)
              |> via_out(:video)
          }
        ]

    {:ok, %{state | spec: spec, tracks: tracks}}
  end

  @impl true
  def handle_element_end_of_stream(:sink, _pad, _ctx, state) do
    {[terminate: :normal], state}
  end

  @impl true
  def handle_element_end_of_stream(_child, _pad, _ctx, state) do
    {[], state}
  end
end
