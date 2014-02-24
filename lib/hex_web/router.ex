defmodule HexWeb.Router do
  use Plug.Router
  import Plug.Connection
  import HexWeb.Util, only: [url: 1]
  import HexWeb.Router.Util
  alias HexWeb.Plugs
  alias HexWeb.RegistryBuilder

  @archive_url "http://hexpm.s3.amazonaws.com/archives/hex.ez"

  plug HexWeb.Plugs.Exception
  plug :match
  plug :dispatch


  get "api/registry" do
    conn = HexWeb.Plugs.Accept.call(conn, vendor: "hex", allow: ["dets"])
    send_file(conn, 200, RegistryBuilder.latest_file)
  end

  get "archives/hex.ez" do
    conn
    |> put_resp_header("location", @archive_url)
    |> send_resp(302, "")
  end

  get "archives" do
    body = [
      dev: [
        version: "0.0.1-dev",
        url: url(["archives", "hex.ez"]) ] ]

    conn
    |> Plug.Parsers.call(parsers: [HexWeb.Parsers.Json, HexWeb.Parsers.Elixir])
    |> Plugs.Accept.call(vendor: "hex", allow: [{"application","json"}, "json", "elixir"])
    |> Plugs.Version.call([])
    |> send_render(200, body)
  end

  forward "/api", HexWeb.Router.API

  match _ do
    send_resp(conn, 404, "")
  end
end