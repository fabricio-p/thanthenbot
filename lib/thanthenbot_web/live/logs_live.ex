defmodule ThanthenbotWeb.LogsLive do
  use ThanthenbotWeb, :live_view

  alias Thanthenbot.Message
  alias ThanthenbotWeb.Router

  def mount(_params, _session, socket) do
    socket = assign_new(socket, :sorting, fn -> %{sort_dir: :asc} end)
    {:ok, socket}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, assign_logs(socket)}
  end


  def handle_info({:update, opts}, socket) do
    path = Router.live_path(socket, __MODULE__, opts)
    {:noreply, push_patch(socket, to: path, replace: true)}
  end

  defp assign_logs(socket) do
    assign(socket, :message_logs, Thanthenbot.list_messages(%{}))
  end
end
