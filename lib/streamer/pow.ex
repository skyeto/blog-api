defmodule Streamer.Pow do
  # TODO: Refactor out secret loading

  def generate(n \\ 10, difficulty \\ 130) do
    puzzle =
      timestamp() <>
        account_id() <>
        app_id() <>
        puzzle_version() <>
        puzzle_expiry() <>
        number_of_puzzles(n) <>
        puzzle_difficulty(difficulty) <>
        <<0::size(64)>> <>
        random()

    {:ok, priv} = System.get_env("STREAMER_POW_SECRET_KEY") |> Base.decode64()

    signature =
      :crypto.sign(:eddsa, :sha256, {:digest, :crypto.hash(:sha256, puzzle)}, [priv, :ed25519])
      |> Base.encode64()

    Cachex.put(:pow_cache, signature, false)

    {:ok, signature <> "." <> Base.encode64(puzzle)}
    # {:ok,
    # :zlib.compress(
    #   :crypto.sign(:eddsa, :sha256, {:digest, :crypto.hash(:sha256, puzzle)}, [priv, :ed25519]) <>
    #     "." <> puzzle
    # )}
  end

  @doc """
  Verifies a base64 encoded solution to puzzle, returns :ok or {:error, reason}
  """
  @spec verify_solution(String.t()) :: :ok | {:error, String.t()}
  def verify_solution([]), do: {:error, :empty_solution}

  def verify_solution(solution) do
    s = String.split(solution, ".")

    case verify_signature(s) do
      :ok ->
        Cachex.put(:pow_cache, hd(s), true)
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp verify_signature([signature, puzzle, solutions, _diagnostic]) do
    # TODO: Add config option to set puzzle secret
    # puzzle_test =
    #  :crypto.mac(:hmac, :sha256, "secret", Base.decode64!(puzzle))
    #  |> Base.encode16()
    #  |> String.slice(0..31)

    {:ok, pub} = System.get_env("STREAMER_POW_PUBLIC_KEY") |> Base.decode64()

    puzzle_test =
      :crypto.verify(
        :eddsa,
        :sha256,
        {:digest, :crypto.hash(:sha256, Base.decode64!(puzzle))},
        Base.decode64!(signature),
        [pub, :ed25519]
      )

    case puzzle_test do
      true ->
        puzzle_map = puzzle_to_map(Base.decode64!(puzzle))
        check_expiry(signature, puzzle, puzzle_map, solutions)

      false ->
        {:error, "Signatures don't match"}
    end
  end

  defp verify_signature(_), do: {:error, "Malformed request"}

  # Puzzles expire after puzzle[:puzzle_expiry] * 5min
  defp check_expiry(signature, puzzle_binary, puzzle, solutions) do
    current_time = DateTime.utc_now() |> DateTime.to_unix()

    case puzzle[:puzzle_expiry] * 300 + puzzle[:timestamp] > current_time do
      true ->
        check_puzzle_replay(signature, puzzle_binary, puzzle, solutions)

      false ->
        {:error, "Expired puzzle"}
    end
  end

  defp check_puzzle_replay(signature, puzzle_binary, puzzle, solutions) do
    case Cachex.get(:pow_cache, signature) do
      {:ok, false} ->
        check_account(puzzle_binary, puzzle, solutions)

      {:ok, true} ->
        {:error, "Proof of work replay"}

      {:ok, nil} ->
        {:error, "Unknown puzzle"}

      _ ->
        {:error, "Unkown puzzle cache error"}
    end
  end

  defp check_account(puzzle_binary, puzzle, solutions) do
    case puzzle[:account_id] do
      1 ->
        check_app_id(puzzle_binary, puzzle, solutions)

      _ ->
        {:error, "Account id doesn't match"}
    end
  end

  defp check_app_id(puzzle_binary, puzzle, solutions) do
    case puzzle[:app_id] do
      1 ->
        check_puzzle_version(puzzle_binary, puzzle, solutions)

      _ ->
        {:error, "App id doesn't match"}
    end
  end

  defp check_puzzle_version(puzzle_binary, puzzle, solutions) do
    case puzzle[:puzzle_version] do
      1 ->
        check_puzzle_solutions(puzzle_binary, puzzle, Base.decode64!(solutions))

      _ ->
        {:error, "Puzzle version doesn't match"}
    end
  end

  defp check_puzzle_solutions(puzzle_binary, puzzle, solutions) do
    _check_puzzle_solutions(puzzle_binary, puzzle, solutions, 0, [])
  end

  defp _check_puzzle_solutions(_, puzzle, <<>>, acc, _) do
    case puzzle[:number_of_puzzles] do
      ^acc ->
        :ok

      _ ->
        {:error, "Mismatched number of solutions"}
    end
  end

  defp _check_puzzle_solutions(
         puzzle_binary,
         puzzle,
         <<solution::binary-size(8), rest::binary>>,
         acc,
         prev
       ) do
    if Enum.member?(prev, solution) == true do
      {:error, "Duplicate solve"}
    else
      case check_puzzle_solution(puzzle_binary, puzzle, solution) do
        true ->
          _check_puzzle_solutions(puzzle_binary, puzzle, rest, acc + 1, [solution | prev])

        false ->
          {:error, "Failed verification"}
      end
    end
  end

  defp _check_puzzle_solutions(_, _, _, _, _), do: {:error, "Malformed puzzle solutions"}

  defp pad(b, n) when b |> byte_size |> rem(n) == 0, do: b
  defp pad(b, n), do: pad(b <> <<0>>, n)

  defp check_puzzle_solution(puzzle_binary, puzzle, solution) do
    IO.inspect(solution)
    test = pad(Base.decode64!(puzzle_binary), 120) <> solution
    <<t::size(32)-unsigned-little, _::binary-size(28)>> = Blake2.Blake2b.hash(test, <<>>, 32)
    IO.inspect(t)
    # <<t::size(32)-unsigned-little>> = :crypto.hash(:blake2b, test)
    threshold = floor(:math.pow(2, (255.999 - puzzle[:puzzle_difficulty]) / 8))

    if t >= threshold do
      false
    else
      true
    end
  end

  defp timestamp() do
    <<DateTime.utc_now() |> DateTime.to_unix()::size(32)>>
  end

  defp account_id() do
    <<1::size(32)>>
  end

  defp app_id() do
    <<1::size(32)>>
  end

  defp puzzle_version() do
    <<1::size(8)>>
  end

  defp puzzle_expiry() do
    <<1::size(8)>>
  end

  defp number_of_puzzles(n) do
    <<n::size(8)>>
  end

  defp puzzle_difficulty(difficulty) do
    # <<137::size(8)>>
    <<difficulty::size(8)>>
  end

  defp random() do
    <<Enum.random(0..255)::size(8), Enum.random(0..255)::size(8), Enum.random(0..255)::size(8),
      Enum.random(0..255)::size(8), Enum.random(0..255)::size(8), Enum.random(0..255)::size(8),
      Enum.random(0..255)::size(8), Enum.random(0..255)::size(8)>>
  end

  defp puzzle_to_map(puzzle) do
    <<timestamp::size(32), account_id::size(32), app_id::size(32), puzzle_version::size(8),
      puzzle_expiry::size(8), number_of_puzzles::size(8), puzzle_difficulty::size(8),
      <<0::size(64)>>, random::size(64)>> = puzzle

    %{
      timestamp: timestamp,
      account_id: account_id,
      app_id: app_id,
      puzzle_version: puzzle_version,
      puzzle_expiry: puzzle_expiry,
      number_of_puzzles: number_of_puzzles,
      puzzle_difficulty: puzzle_difficulty,
      random: random
    }
  end
end
