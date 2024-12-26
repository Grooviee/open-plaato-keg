defmodule OpenPlaatoKeg.Models.KegDataOutput do
  alias OpenPlaatoKeg.Models.KegData
  alias OpenPlaatoKeg.Models.KegDataCalibration

  defstruct id: nil,
            weight_raw: nil,
            weight_raw_unit: nil,
            temperature_raw: nil,
            temperature_raw_unit: nil,
            weight: nil,
            weight_calibrate: 0,
            temperature: nil,
            temperature_calibrate: 0

  def get(id) do
    case KegData.get(id) do
      nil ->
        nil

      %KegData{} = keg_data ->
        calibration = KegDataCalibration.get(id)

        merge(keg_data, calibration)
    end
  end

  def get do
    KegData.keys()
    |> Enum.map(&get/1)
  end

  defp merge(%KegData{} = keg_data, %KegDataCalibration{} = calibration) do
    keg_data
    |> Map.merge(calibration)
    |> Map.delete(:__struct__)
    |> then(fn data ->
      struct(__MODULE__, data)
    end)
    |> recalculate()
  end

  defp recalculate(data) do
    %{
      data
      | weight: safe_sum(data.weight_raw, data.weight_calibrate),
        temperature: safe_sum(data.temperature_raw, data.temperature_calibrate)
    }
  end

  defp safe_sum(value, addition) when is_number(value) do
    value + (addition || 0)
  end

  defp safe_sum(_value, _addition), do: nil
end
