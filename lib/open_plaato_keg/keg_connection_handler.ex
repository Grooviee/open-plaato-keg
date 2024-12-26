defmodule OpenPlaatoKeg.KegConnectionHandler do
  use ThousandIsland.Handler
  alias OpenPlaatoKeg.BlynkProtocol

  def handle_connection(_socket, _state) do
    {:ok, pid} = GenServer.start_link(OpenPlaatoKeg.KegDataProcessor, %{})
    Process.link(pid)

    state = %{keg_data_processor: pid}
    {:continue, state}
  end

  def handle_data(data, socket, state) do
    ThousandIsland.Socket.send(socket, BlynkProtocol.response_success())
    GenServer.cast(state.keg_data_processor, {:keg_data, data})

    {:continue, state}
  end
end
