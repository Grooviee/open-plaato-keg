defmodule OpenPlaatoKeg.Models.KegDataCalibration do
  defstruct id: nil,
            name: nil,
            weight_calibrate: 0,
            temperature_calibrate: 0

  def new(input) do
    %__MODULE__{
      id: input["id"],
      name: input["name"],
      weight_calibrate: input["weight_calibrate"],
      temperature_calibrate: input["temperature_calibrate"]
    }
  end

  def get(id) do
    case :ets.lookup(:keg_data, {id, :calibration}) do
      [{_, model}] -> model
      [] -> %__MODULE__{id: id}
    end
  end

  def insert(%__MODULE__{} = model) do
    :ets.insert(:keg_data, {{model.id, :calibration}, model})
  end
end
