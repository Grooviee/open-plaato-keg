defmodule OpenPlaatoKeg.OtaRouter do
  @moduledoc """
  Wrapper plug that serves an ESP32 firmware test image before handing all other
  traffic to the normal HTTP router.

  For lab testing with a personally owned PLAATO Keg, place a compatible ESP32
  app image at the configured firmware path and request `/download32.php`.
  """

  @behaviour Plug
  import Plug.Conn
  require Logger

  @firmware_path "/download32.php"

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{method: method, request_path: @firmware_path} = conn, _opts)
      when method in ["GET", "HEAD"] do
    serve_firmware(conn, method)
  end

  def call(conn, opts) do
    OpenPlaatoKeg.HttpRouter.call(conn, OpenPlaatoKeg.HttpRouter.init(opts))
  end

  defp serve_firmware(conn, method) do
    path = configured_firmware_path()

    case File.read(path) do
      {:ok, firmware} ->
        size = byte_size(firmware)
        md5 = firmware |> :crypto.hash(:md5) |> Base.encode16(case: :lower)
        version = configured_version()

        Logger.info("Serving ESP32 firmware #{path} size=#{size} md5=#{md5} version=#{version}")

        conn =
          conn
          |> put_resp_content_type("application/octet-stream")
          |> put_resp_header("cache-control", "no-cache")
          |> put_resp_header("content-disposition", ~s(inline; filename="firmware.bin"))
          |> put_resp_header("content-length", Integer.to_string(size))
          |> put_resp_header("x-ESP32-sketch-md5", md5)
          |> put_resp_header("x-ESP32-sketch-size", Integer.to_string(size))
          |> put_resp_header("x-ESP32-version", version)

        if method == "HEAD" do
          send_resp(conn, 200, "")
        else
          send_resp(conn, 200, firmware)
        end

      {:error, reason} ->
        Logger.warning("ESP32 firmware file not available at #{path}: #{inspect(reason)}")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Poison.encode!(%{error: "firmware_not_found", path: path}))
    end
  end

  defp configured_firmware_path do
    Application.get_env(:open_plaato_keg, :ota, [])
    |> Keyword.get(:firmware_path, "priv/ota/firmware.bin")
  end

  defp configured_version do
    Application.get_env(:open_plaato_keg, :ota, [])
    |> Keyword.get(:version, "test")
  end
end
