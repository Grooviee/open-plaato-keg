defmodule OpenPlaatoKeg.KegDataProcessor do
  use GenServer
  require Logger
  alias OpenPlaatoKeg.BlynkProtocol
  alias OpenPlaatoKeg.Models.KegData
  alias OpenPlaatoKeg.Models.KegDataCalibration
  alias OpenPlaatoKeg.Models.KegDataOutput
  alias OpenPlaatoKeg.PlaatoProtocol

  def start_link(_ \\ %{}) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:keg_data, data}, state) do
    decoded_data = decode(data)

    state =
      if decoded_data != [] do
        Logger.debug("Decoded keg data", data: inspect(decoded_data, limit: :infinity))

        weight_changed? =
          decoded_data
          |> List.flatten()
          |> Enum.any?(fn {key, _value} -> key == :weight_raw end)

        new_state =
          decoded_data
          |> Enum.reduce(state, fn {key, value}, acc ->
            Map.put(acc, key, value)
          end)
          |> then(fn state ->
            state = struct(KegData, state)
            KegData.insert(state)
            state
          end)

        broadcast_to_websocket(new_state)

        if OpenPlaatoKeg.mqtt_config()[:enabled] do
          publish_to_mqtt(new_state)
        end

        if weight_changed? and OpenPlaatoKeg.barhelper_config()[:enabled] do
          publish_to_barhelper(new_state)
        end

        Map.from_struct(new_state)
      else
        state
      end

    {:noreply, state}
  end

  def update_calibration_data(
        %{
          "name" => name,
          "id" => _id,
          "weight_calibrate" => weight_calibrate,
          "temperature_calibrate" => temperature_calibrate
        } = input
      )
      when is_number(weight_calibrate) and is_number(temperature_calibrate) and is_binary(name) do
    input
    |> KegDataCalibration.new()
    |> KegDataCalibration.insert()

    {:ok, nil}
  end

  def update_calibration_data(_), do: {:error, "invalid_parameters"}

  defp decode(data) do
    data
    |> BlynkProtocol.decode()
    |> PlaatoProtocol.decode()
    |> PlaatoProtocol.decode_data()
  end

  defp broadcast_to_websocket(data) do
    case KegDataOutput.get(data.id) do
      nil ->
        :skip

      %KegDataOutput{} = keg_data ->
        keg_data
        |> Poison.encode!()
        |> OpenPlaatoKeg.WebSocketHandler.broadcast()
    end
  end

  defp publish_to_mqtt(data) do
    case KegDataOutput.get(data.id) do
      nil ->
        :skip

      %KegDataOutput{} = keg_data ->
        OpenPlaatoKeg.MqttHandler.publish(keg_data)
    end
  end

  defp publish_to_barhelper(data) do
    case KegDataOutput.get(data.id) do
      nil ->
        :skip

      %KegDataOutput{} = keg_data ->
        OpenPlaatoKeg.BarHelper.publish(keg_data)
    end
  end
end
