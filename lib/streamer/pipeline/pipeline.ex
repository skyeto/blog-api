defmodule Streamer.Pipeline do
  require Logger
  alias Streamer.Pipeline.HLSSink
  use Membrane.Pipeline

  defmodule State do
    defstruct [:status, :hls_storage_module, :spec, :tracks]

    @type status ::
            :init
            | :awaiting_output
            | :output_ready
            | :awaiting_input
            | :input_ready
            | :awaiting_link
            | :link_ready
            | :running

    @type t :: %__MODULE__{
            status: status(),
            spec: [],
            tracks: [],
            hls_storage_module: pid()
          }
  end

  def start_link(opts) do
    Membrane.Pipeline.start_link(__MODULE__, opts, name: Streamer.Pipeline)
  end

  def handle_init(_ctx, _opts) do
    state = %State{
      status: :init,
      spec: [],
      tracks: []
    }

    {:ok, state} = proceed(state)

    structure = state.spec

    {[spec: structure], state}
  end

  @impl true
  def handle_info(
        {:new_rtmp_client, client_ref},
        _ctx,
        state
      ) do
    spec =
      [
        child(:rtmp_source, %Membrane.RTMP.SourceBin{client_ref: client_ref}),
        get_child(:rtmp_source)
        |> via_out(:audio)
        |> child(Membrane.AAC.Parser)
        |> child(Membrane.AAC.FDK.Decoder)
        |> child(%Membrane.FFmpeg.SWResample.Converter{
          output_stream_format: %Membrane.RawAudio{
            channels: 2,
            sample_rate: 48_000,
            sample_format: :s16le
          }
        })
        |> child(Membrane.AAC.FDK.Encoder)
        |> get_child(:hls_audio_funnel),
        get_child(:rtmp_source)
        |> via_out(:video)
        # |> get_child(:hls_video_funnel)
        |> child(:fake_sink, Membrane.Fake.Sink.Buffers)
      ]

    {[spec: spec], %{state | spec: spec ++ state.spec}}
  end

  defp proceed(%{status: :init} = state) do
    proceed(%{state | status: :awaiting_output})
  end

  defp proceed(%{status: :awaiting_output} = state) do
    {:ok, state} = create_output(:hls_storage, state)
    {:ok, state} = create_output(:hls_sink, state)

    proceed(%{state | status: :output_ready})
  end

  defp proceed(%{status: :output_ready} = state) do
    proceed(%{state | status: :awaiting_input})
  end

  defp proceed(%{status: :awaiting_input} = state) do
    {:ok, state} = create_input(:rtmp, state)
    # {:ok, state} = create_input(:live_audio_mix, state)

    proceed(%{state | status: :input_ready})
  end

  defp proceed(%{status: :input_ready} = state) do
    proceed(%{state | status: :awaiting_link})
  end

  defp proceed(%{status: :awaiting_link, spec: spec_builder, tracks: track_builders} = state) do
    # mixer = Keyword.get(track_builders, :audio_mixer).audio

    spec =
      spec_builder ++
        [
          #  mixer
          #  |> child(:aac_encoder, Membrane.AAC.FDK.Encoder)
          #  |> via_out(:output)
          #  |> via_in(Pad.ref(:input, :audio), options: [encoding: :AAC, segment_duration: 2000])
          #  |> get_child(:hls_sink_bin)
        ]

    proceed(%{state | status: :link_ready, spec: spec})
  end

  defp proceed(%{status: :link_ready} = state) do
    {:ok, %{state | status: :running}}
  end

  defp create_output(:hls_storage, state) do
    {:ok, storage_pid} =
      case GenServer.start_link(Streamer.HLSStorage, %{encryption: true},
             name: {:global, :audio_master_storage}
           ) do
        {:error, {:already_started, pid}} ->
          Logger.error("audio storage already running?")
          {:ok, pid}

        {:ok, _pid} = p ->
          p

        _ ->
          {:error, %{reason: "failed to start HLS storage service"}}
      end

    {:ok, %{state | hls_storage_module: storage_pid}}
  end

  defp create_output(:hls_sink, state) do
    Streamer.Pipeline.HLSSink.create_output(state)
  end

  defp create_input(:live_audio_mix, state) do
    Streamer.Pipeline.AudioMixer.create_input(state)
  end

  defp create_input(:rtmp, state) do
    pipeline_pid = self()

    rtmp_config = [
      port: 1935,
      use_ssl?: false,
      handle_new_client: fn client_ref, app, stream_key ->
        if stream_key == "abc123" do
          send(pipeline_pid, {:new_rtmp_client, client_ref})
          Membrane.RTMP.Source.ClientHandlerImpl
        else
          Logger.warning("Unpexpected client #{app} #{stream_key}")
        end
      end
    ]

    Membrane.RTMPServer.start_link(rtmp_config)

    {:ok, state}
  end
end
