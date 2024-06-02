defmodule ThanthenbotWeb.LogsController do
  use ThanthenbotWeb, :controller

  alias Thanthenbot.Repo

  def index(conn, _params) do
    entries = Repo.all(Thanthenbot.Message)
    render(conn, :index, entries: entries)
  end
end
