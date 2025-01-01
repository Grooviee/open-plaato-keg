defmodule OpenPlaatoKeg.PlaatoProtocol do
  require Logger

  def decode({:hardware, _, _, message}) do
    case String.split(message, "\0", trim: true) do
      [_, id, data] ->
        {id, data}

      data ->
        {:unknown_hardware, data}
    end
  end

  def decode({:internal, _, _, message}) do
    internal_props =
      message
      |> String.split("\0", trim: true)
      |> Enum.chunk_every(2)
      |> Enum.map(fn [key, value] -> {key, value} end)
      |> Enum.into(%{})

    {:internal, internal_props}
  end

  def decode({:hardware_sync, _, _, message}) do
    props =
      message
      |> String.split("\0", trim: true)

    {:hardware_sync, props}
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

  def decode_data({"69", data}) do
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
