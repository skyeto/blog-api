defmodule Streamer.Pipeline.RTMP do
  use Membrane.Pipeline

  alias Membrane.HTTPAdaptiveStream.{
    SinkBin,
    Manifest,
    HLS,
    Storages
  }

  @impl true
  def handle_init(_ctx, opts) do
    IO.inspect(opts)

    state = %{client_ref: opts.client_ref, metadata: nil}

    {:ok, storage_pid} =
      case GenServer.start_link(Streamer.HLSStorage, %{encryption: true},
             name: {:global, :audio_master_storage}
           ) do
        {:error, {:already_started, pid}} -> {:ok, pid}
        {:ok, _} = p -> p
        _ -> {:error, %{reason: "uuh"}}
      end

    structure = [
      # Source
      child(:source, %Membrane.RTMP.SourceBin{client_ref: opts.client_ref}),
      # Sink
      child(:sink, %SinkBin{
        manifest_name: "radio",
        manifest_module: HLS,
        storage: %Storages.GenServerStorage{
          destination: storage_pid,
          method: :cast
        },
        target_window_duration: Membrane.Time.seconds(120),
        segment_naming_fun: &segment_naming_fun/1,
        persist?: false,
        mode: :live,
        hls_mode: :separate_av
      }),
      # Segment audio and send to HLS sink
      get_child(:source)
      |> via_out(:audio)
      |> via_in(Pad.ref(:input, "audio_master"),
        options: [encoding: :AAC, segment_duration: Membrane.Time.milliseconds(2000)]
      )
      |> get_child(:sink),
      # Throw out video
      get_child(:source)
      |> via_out(:video)
      |> child(Membrane.Fake.Sink.Buffers)
    ]

    {[spec: structure], state}
  end

  @impl true
  def handle_element_end_of_stream(:sink, _pad, _ctx, state) do
    Process.exit({:global, :audio_master_storage})
    {[terminate: :normal], state}
  end

  @impl true
  def handle_element_end_of_stream(_child, _pad, _ctx, state) do
    {[], state}
  end

  def handle_new_client(client_ref, app, stream_key) do
    # TODO: Check stream keyh
    IO.inspect(stream_key)

    {:ok, _sup, pid} =
      Membrane.Pipeline.start_link(Streamer.Pipeline.RTMP, %{
        client_ref: client_ref,
        app: app,
        stream_key: stream_key
      })

    {Streamer.RTMPClientHandler, %{pipeline: pid}}
  end

  @spec segment_naming_fun(Manifest.Track.t()) :: String.t()
  defp segment_naming_fun(track) do
    name = Enum.join([track.content_type, "sgmnt", track.next_segment_id, track.track_name], "_")
    Enum.join([name, Murmur.hash_x86_32(name, 0) |> Integer.to_string(16)], "-")
  end
end
