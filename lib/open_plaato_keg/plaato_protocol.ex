defmodule OpenPlaatoKeg.PlaatoProtocol do
  require Logger

  def decode({:hardware, _, _, <<_, _, _, id_1, id_2, _>> <> data} = input) do
    id = <<id_1, id_2>>
    {id, data}
  rescue
    error ->
      Logger.error("Failed to decode hardware data",
        data: inspect([input: input, error: error], limit: :infinity)
      )

      {:error, error}
  end

  def decode({:notify, _, _, notify}), do: {:notify, notify}
  def decode({:get_shared_dash, _, _, dash}), do: {:get_shared_dash, dash}
  def decode({:ping, sequence, _, _}), do: {:ping, sequence}
  def decode({:property, _, _, value}), do: {:property, value}
  def decode(unknown), do: {:unknown, unknown}

  def decode_data({:get_shared_dash, dash}) do
    [{:id, dash}]
  end

  def decode_data({"51", data}) do
    [{:weight_raw, String.to_float(data)}]
  rescue
    _ -> []
  end

  def decode_data({"74", data}) do
    [{:weight_raw_unit, data}]
  end

  def decode_data({"92", data}) do
    {temperature, unit} = Float.parse(data)
    unit_sliced = String.slice(unit, 0, 2)
    [{:temperature_raw, temperature}, {:temperature_raw_unit, unit_sliced}]
  rescue
    _ ->
      Logger.error("Failed to decode temperature data",
        data: data
      )

      []
  end

  def decode_data(_) do
    []
  end
end
