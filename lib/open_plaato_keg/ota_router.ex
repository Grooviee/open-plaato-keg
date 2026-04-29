defmodule OpenPlaatoKeg.OtaRouter do
  @moduledoc """
  Wrapper plug that serves an ESP32 firmware test image before handing all other
  traffic to the normal HTTP router.
  """

  @behaviour Plug
  import Plug.Conn
  require Logger

  @firmware_path "/download32.php"
  @setup_path "/setup.html"

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{method: method, request_path: @firmware_path} = conn, _opts)
      when method in ["GET", "HEAD"] do
    serve_firmware(conn, method)
  end

  def call(%Plug.Conn{method: "GET", request_path: @setup_path} = conn, _opts) do
    serve_setup_page(conn)
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
          |> put_resp_header("content-disposition", ~s(inline; filename="#{Path.basename(path)}"))
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

  defp serve_setup_page(conn) do
    setup_path = Path.join(:code.priv_dir(:open_plaato_keg), "static/setup.html")

    case File.read(setup_path) do
      {:ok, html} ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, add_simple_firmware_button(html))

      {:error, reason} ->
        Logger.warning("Could not read setup page at #{setup_path}: #{inspect(reason)}")
        OpenPlaatoKeg.HttpRouter.call(conn, OpenPlaatoKeg.HttpRouter.init([]))
    end
  end

  defp add_simple_firmware_button(html) do
    html
    |> String.replace("onclick=\"triggerOtaUpdate()\">\n                        Send OTA", "onclick=\"triggerSimpleOta()\">\n                        🔥 Update Firmware")
    |> String.replace(~r/<input class="input" type="text" id="otaFirmwarePath"[\s\S]*?<\/div>\s*<div class="control">/, "<div class=\"control\">")
    |> add_simple_firmware_js()
  end

  defp add_simple_firmware_js(html) do
    if String.contains?(html, "function triggerSimpleOta()") do
      html
    else
      String.replace(html, "</script>", simple_firmware_js() <> "\n    </script>", global: false)
    end
  end

  defp simple_firmware_js do
    """

      function triggerSimpleOta() {
        const kegId = getSelectedKeg();
        if (!kegId) return;

        if (!confirm("Start firmware update from /download32.php?")) {
          return;
        }

        fetch(`/api/kegs/${kegId}/ota`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ path: "/download32.php" })
        })
          .then((response) => response.json())
          .then((data) => {
            if (data.status === "ok") {
              showToast("Firmware update command sent", "success");
            } else {
              showToast(`Error: ${data.error}`, "danger");
            }
          })
          .catch((err) => {
            showToast(`Error: ${err.message}`, "danger");
          });
      }
    """
  end

  defp configured_firmware_path do
    configured =
      Application.get_env(:open_plaato_keg, :ota, [])
      |> Keyword.get(:firmware_path, "priv/ota/firmware.bin")

    cond do
      File.exists?(configured) -> configured
      File.exists?("priv/ota/plaatoV2.11b") -> "priv/ota/plaatoV2.11b"
      true -> first_file_in_ota_folder(configured)
    end
  end

  defp first_file_in_ota_folder(default_path) do
    case Path.wildcard("priv/ota/*") |> Enum.filter(&File.regular?/1) do
      [first | _] -> first
      [] -> default_path
    end
  end

  defp configured_version do
    Application.get_env(:open_plaato_keg, :ota, [])
    |> Keyword.get(:version, "plaatoV2.11b-test")
  end
end
