defmodule OpenPlaatoKeg.Models.KegDataCalibration do
  defstruct id: nil,
            name: "",
            full_weight: 19,
            weight_calibrate: 0,
            temperature_calibrate: 0

  def new(input) do
    %__MODULE__{
      id: input["id"],
      name: input["name"],
      full_weight: input["full_weight"],
      weight_calibrate: input["weight_calibrate"],
      temperature_calibrate: input["temperature_calibrate"]
    }
  end

  def get(id) do
    case :dets.lookup(:keg_data, {id, :calibration}) do
      [{_, model}] -> model
      [] -> %__MODULE__{id: id}
    end
  end

  def insert(%__MODULE__{} = model) do
    :dets.insert(:keg_data, {{model.id, :calibration}, model})
  end
end
