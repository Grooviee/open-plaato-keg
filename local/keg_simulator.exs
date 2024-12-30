defmodule KegSimulator do
  @host ~c"localhost"
  @port 1234

  def list_binaries do
    folder = "local/bin"

    folder
    |> File.ls!()
    |> Enum.sort_by(fn x -> String.replace(x, ".bin", "") |> String.to_integer() end)
    |> Enum.map(fn x -> Path.join(folder, x) end)

  end

  def start do
    {:ok, socket} = :gen_tcp.connect(@host, @port, [:binary, active: false])

    files = list_binaries()

    files
    |> Enum.map(&File.read!(&1))
    |> Enum.with_index()
    |> Enum.each(&send_data_and_wait_for_ok(&1, socket))
  end

  defp send_data_and_wait_for_ok({data, index}, socket) do
    IO.inspect("[#{index}] Sending: #{inspect(data)}")
    IO.inspect(data, [{:binaries, :as_strings}])
    :gen_tcp.send(socket, data)

    case :gen_tcp.recv(socket, 0) do
      {:ok, response} ->
        IO.inspect("Response: #{inspect(response)}")
        :timer.sleep(50)

      error ->
        {:error, IO.inspect(error)}
        :gen_tcp.close(socket)
        :c.q()
    end
  end
end

KegSimulator.start()
