defmodule Streamer.HLSStorage do
  alias Jason.Encode
  use GenServer

  require Logger

  @impl true
  def init(state) do
    key = if state[:encryption] == true, do: generate_key()

    initial_state = %{
      encryption: key,
      last_segment: DateTime.from_unix!(0)
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_cast(
        {Membrane.HTTPAdaptiveStream.Storages.GenServerStorage, :store,
         %{name: name, type: type, contents: content} = op},
        state
      ) do
    IO.inspect(type)

    case type do
      :manifest ->
        case is_nil(state.encryption) do
          true ->
            store_manifest(name, content)

          false ->
            tag = keyTag(state.encryption.iv)

            # TODO: silly
            manifest =
              String.replace(
                content,
                "#EXTM3U\n",
                "#EXTM3U\n#{tag}\n",
                global: false
              )

            store_manifest(name, manifest)

            :ok
        end

        {:noreply, state}

      _ ->
        case is_nil(state.encryption) do
          true ->
            store_file(name, content)

          false ->
            ciphertext =
              :crypto.crypto_one_time(
                :aes_128_cbc,
                state.encryption.key,
                state.encryption.iv,
                pad_pkcs(content, 16),
                true
              )

            store_file(name, ciphertext)
        end

        {:noreply, Map.put(state, :last_segment, DateTime.utc_now())}
    end
  end

  @impl true
  def handle_cast(
        {Membrane.HTTPAdaptiveStream.Storages.GenServerStorage, :remove,
         %{name: name, type: type}},
        state
      ) do
    res = ExAws.S3.delete_object("radio", name, []) |> ExAws.request()
    {:noreply, state}
  end

  def handle_cast(
        {Membrane.HTTPAdaptiveStream.Storages.GenServerStorage, :store, %{name: name} = op},
        state
      )
      when not is_map_key(op, :contents) do
    ExAws.S3.delete_object("radio", name, []) |> ExAws.request()
    {:noreply, state}
  end

  def handle_cast({Membrane.HTTPAdaptiveStream.Storages.GenServerStorage, _, _}, state) do
    Logger.error("Unhandled message in HLS Storage")
    {:noreply, state}
  end

  def handle_call(:get_crypto, _, state) do
    {:reply, state.encryption, state}
  end

  def handle_call(:get_stream_status, _, state) do
    online =
      case DateTime.diff(state.last_segment, DateTime.utc_now()) do
        t when t in 0..20 -> :online
        _else -> :offline
      end

    {:reply, online, state}
  end

  @impl true
  def handle_call(call, _, state) do
    Logger.error("Unhandled call")
    IO.inspect(call)
    {:noreply, state}
  end

  defp store_file(name, content) do
    ExAws.S3.put_object("radio", name, content, []) |> ExAws.request()
  end

  defp store_manifest(name, content) do
    ExAws.S3.put_object("radio", name, content, []) |> ExAws.request()
  end

  defp generate_key() do
    iv = :crypto.strong_rand_bytes(16)
    key = :crypto.strong_rand_bytes(16)

    %{iv: iv, key: key}
  end

  defp keyTag(iv) do
    "#EXT-X-KEY:METHOD=AES-128,URI=http://localhost:4000/api/license,IV=0x#{:binary.decode_unsigned(iv) |> Integer.to_string(16)}"
  end

  defp pad_pkcs(data, size) do
    pad = size - rem(byte_size(data), size)
    data <> to_string(List.duplicate(pad, pad))
  end
end
