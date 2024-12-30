defmodule OpenPlaatoKeg.WebSocketHandler do
  def init(state) do
    Registry.register(OpenPlaatoKeg.WebSocketConnectionRegistry, "websocket_clients", self())
    {:ok, state}
  end

  def handle_info({:broadcast, message}, state) do
    {:reply, :ok, {:text, message}, state}
  end

  def terminate(_reason, _state) do
    Registry.unregister(OpenPlaatoKeg.WebSocketConnectionRegistry, "websocket_clients")
    :ok
  end

  def publish(message) do
    json_message = Poison.encode!(message)

    Registry.dispatch(
      OpenPlaatoKeg.WebSocketConnectionRegistry,
      "websocket_clients",
      fn entries ->
        for {pid, _} <- entries do
          send(pid, {:broadcast, json_message})
        end
      end
    )
  end
end
