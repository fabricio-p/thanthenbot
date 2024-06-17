defmodule ThanthenbotWeb.LogsController do
  use ThanthenbotWeb, :controller

  alias Thanthenbot.Repo

  def index(conn, _params) do
    entries = Thanthenbot.list_messages(%{})
    render(conn, :index, entries: entries)
  end
end
