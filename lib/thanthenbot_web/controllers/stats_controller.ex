defmodule ThanthenbotWeb.StatsController do
  use ThanthenbotWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
