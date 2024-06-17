defmodule ThanthenbotWeb.LogsLive do
  use ThanthenbotWeb, :live_view

  require Logger

  alias Thanthenbot.Message

  def mount(_params, _session, socket) do
    socket = assign_new(socket, :sorting, fn -> %{sort_dir: :asc} end)
    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    sort_by = Map.get(params, "sort_by", nil)
    sort_dir = Map.get(params, "sort_dir", nil)

    socket =
      socket
      |> assign_sorting(sort_by, sort_dir)
      |> assign_logs()

    {:noreply, socket}
  end

  def handle_info({:update, opts}, socket) do
    path = Routes.live_path(socket, __MODULE__, opts)
    {:noreply, push_patch(socket, to: path, replace: true)}
  end

  defp assign_sorting(socket, sort_by, sort_dir)
       when sort_by in ~w[guild_id channel_id author_name] and
              sort_dir in ~w[asc desc] do
    sort_by = String.to_atom(sort_by)
    sort_dir = String.to_atom(sort_dir)

    assign(socket, :sorting, %{sort_by: sort_by, sort_dir: sort_dir})
  end

  defp assign_sorting(socket, _sort_by, _sort_dir), do: socket

  defp assign_logs(socket) do
    dbg socket.assigns[:sorting]
    message_logs = Thanthenbot.list_messages(socket.assigns[:sorting])
    assign(socket, :message_logs, message_logs)
  end
end
