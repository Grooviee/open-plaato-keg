import Config

config :logger,
  backends: [:console],
  utc_log: true,
  level: if(config_env() == :prod, do: :info, else: :debug),
  compile_time_purge_matching: [
    [level_lower_than: if(config_env() == :prod, do: :info, else: :debug)]
  ],
  truncate: :infinity

config :logger, :console,
  metadata: [
    :registered_name,
    :mfa,
    :pid,
    :line,
    :crash_reason,
    :data
  ],
  format: "[$level] $metadata msg=$message\n"

config :prometheus,
  mnesia_collector_metrics: [],
  vm_dist_collector_metrics: [],
  vm_msacc_collector_metrics: [],
  vm_memory_collector_metrics: [:bytes_total, :system_bytes_total, :processes_bytes_total],
  vm_system_info_collector_metrics: [:atom_count, :process_count],
  vm_statistics_collector_metrics: [
    :reductions_total,
    :garbage_collection_number_of_gcs,
    :garbage_collection_bytes_reclaimed,
    :garbage_collection_words_reclaimed
  ]
