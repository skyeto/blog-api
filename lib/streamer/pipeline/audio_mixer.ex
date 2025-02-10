defmodule Streamer.Pipeline.AudioMixer do
  use Membrane.Pipeline

  def create_input(%{spec: spec_builder, tracks: tracks_builder} = state) do
    spec =
      spec_builder ++
        [
          child(:mixer, %Membrane.AudioMixer{
            synchronize_buffers?: true,
            stream_format: %Membrane.RawAudio{
              channels: 2,
              sample_rate: 48_000,
              sample_format: :s16le
            }
          })
        ]

    tracks =
      tracks_builder ++
        [
          audio_mixer: %{audio: get_child(:mixer)}
        ]

    {:ok, %{state | spec: spec, tracks: tracks}}
  end
end
