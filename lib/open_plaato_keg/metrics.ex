defmodule OpenPlaatoKeg.Metrics do
  use Prometheus.Metric

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
      name: :plaato_keg_raw_weight,
      help: "Raw weight from Plaato Keg",
      labels: ["unit"],
      registry: :default
    )

    Gauge.declare(
      name: :plaato_keg_raw_weight,
      help: "Raw temperature from Plaato Keg",
      labels: ["unit"],
      registry: :default
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
