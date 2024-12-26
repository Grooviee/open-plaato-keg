defmodule OpenPlaatoKeg.MqttHandler do
  require Logger

  def init(args) do
    Logger.info("", data: inspect(args))
    {:ok, args}
  end

  def connection(status, state) do
    Logger.info("", data: inspect(%{status: status, state: state}))
    {:ok, state}
  end

  def handle_message(topic, payload, state) do
    Logger.debug(
      "Received message on topic #{inspect(topic)}, playload #{payload}, state: #{inspect(state)}"
    )

    {:ok, state}
  end

  def subscription(status, topic_filter, state) do
    Logger.info("", data: inspect(%{status: status, topic_filter: topic_filter, state: state}))
    {:ok, state}
  end

  def terminate(reason, state) do
    Logger.info("", data: inspect(%{reason: reason, state: state}))
    :ok
  end

  def publish(data) do
    Tortoise.publish(
      OpenPlaatoKeg.mqtt_config()[:client],
      "#{OpenPlaatoKeg.mqtt_config()[:topic]}/#{data.id}",
      Poison.encode!(data),
      qos: 0,
      retain: true
    )
  end
end
