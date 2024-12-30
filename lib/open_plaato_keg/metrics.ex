defmodule OpenPlaatoKeg.Metrics do
  use Prometheus.Metric
  require Logger

  def init do
    Summary.declare(
      name: :telemetry_scrape_duration_seconds,
      help: "Scrape duration",
      labels: ["registry"],
      registry: :default
    )

    Summary.declare(
      name: :telemetry_scrape_size_bytes,
      help: "Scrape size, uncompressed",
      labels: ["registry"],
      registry: :default
    )

    Gauge.declare(
      name: :plaato_keg_weight,
      help: "Weight from Plaato Keg",
      labels: ["id", "type", "unit"],
      registry: :default
    )

    Gauge.declare(
      name: :plaato_keg_temperature,
      help: "Temperature from Plaato Keg",
      labels: ["id", "type", "unit"],
      registry: :default
    )
  end

  def publish(keg_data) do
    if keg_data.temperature_raw do
      Gauge.set(
        [
          name: :plaato_keg_temperature,
          labels: [keg_data.id, "raw", keg_data.temperature_raw_unit || ""]
        ],
        keg_data.temperature_raw
      )

      Gauge.set(
        [
          name: :plaato_keg_temperature,
          labels: [keg_data.id, "calibrate", keg_data.temperature_raw_unit || ""]
        ],
        keg_data.temperature_calibrate
      )

      Gauge.set(
        [
          name: :plaato_keg_temperature,
          labels: [keg_data.id, "current", keg_data.temperature_raw_unit || ""]
        ],
        keg_data.temperature
      )
    end

    if keg_data.weight_raw do
      Gauge.set(
        [
          name: :plaato_keg_weight,
          labels: [keg_data.id, "raw", keg_data.weight_raw_unit || ""]
        ],
        keg_data.weight_raw
      )

      Gauge.set(
        [
          name: :plaato_keg_weight,
          labels: [keg_data.id, "calibrate", keg_data.weight_raw_unit || ""]
        ],
        keg_data.weight_calibrate
      )

      Gauge.set(
        [
          name: :plaato_keg_weight,
          labels: [keg_data.id, "current", keg_data.weight_raw_unit || ""]
        ],
        keg_data.weight
      )
    end
  rescue
    error ->
      Logger.error("Failed to publish metrics",
        data: inspect([keg_data: keg_data, error: error], limit: :infinity)
      )
  end

  def scrape_data(format \\ :prometheus_text_format, registry \\ :default) do
    scrape =
      Summary.observe_duration(
        [
          registry: registry,
          name: :telemetry_scrape_duration_seconds,
          labels: [registry]
        ],
        fn ->
          format.format(registry)
        end
      )

    Summary.observe(
      [registry: registry, name: :telemetry_scrape_size_bytes, labels: [registry]],
      :erlang.iolist_size(scrape)
    )

    scrape
  end
end
