defmodule OpenPlaatoKeg.HttpRouter do
  use Plug.Router
  alias OpenPlaatoKeg.KegDataProcessor
  alias OpenPlaatoKeg.Models.KegData
  alias OpenPlaatoKeg.Models.KegDataOutput

  plug(Plug.Static,
    at: "/",
    from: :open_plaato_keg
  )

  plug(Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  get "api/kegs/devices" do
    data = KegData.keys()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(data))
  end

  get "api/kegs" do
    data = KegDataOutput.get()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(data))
  end

  get "api/kegs/:id" do
    case KegDataOutput.get(conn.params["id"]) do
      %KegDataOutput{} = data ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Poison.encode!(data))

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Poison.encode!(%{error: "not_found"}))
    end
  end

  post "api/kegs/calibrate" do
    case KegDataProcessor.update_calibration_data(conn.body_params) do
      {:ok, _} ->
        conn
        |> send_resp(201, "")

      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{error: reason}))
    end
  end

  get "/api/metrics" do
    conn
    |> put_resp_content_type(:prometheus_text_format.content_type())
    |> send_resp(200, OpenPlaatoKeg.Metrics.scrape_data())
  end

  get "/ws" do
    conn
    |> WebSockAdapter.upgrade(OpenPlaatoKeg.WebSocketHandler, [], timeout: :infinity)
    |> halt()
  end

  get "/api/alive" do
    send_resp(conn, 200, "1")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
