defmodule OpenPlaatoKeg do
  use Application

  def start(_type, _args) do
    OpenPlaatoKeg.Metrics.init()
    bootstrap()
    OpenPlaatoKeg.Supervisor.start_link()
  end

  def bootstrap do
    :ets.new(:keg_data, [
      :set,
      :named_table,
      :public,
      read_concurrency: true,
      write_concurrency: false
    ])
  end

  def tcp_listener_config do
    Application.get_env(:open_plaato_keg, :tcp_listener)
  end

  def http_listener_config do
    Application.get_env(:open_plaato_keg, :http_listener)
  end

  def mqtt_config do
    Application.get_env(:open_plaato_keg, :mqtt)
  end

  def barhelper_config do
    Application.get_env(:open_plaato_keg, :barhelper)
  end
end
