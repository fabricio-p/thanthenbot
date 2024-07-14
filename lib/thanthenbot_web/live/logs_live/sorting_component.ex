defmodule ThanthenbotWeb.LogsLive.SortingComponent do
  use ThanthenbotWeb, :live_component

  attr :id, :string
  attr :name, :string, required: true
  attr :key, :atom, required: true
  attr :sorting, :map, required: true

  def render(assigns) do
    ~H"""
    <div phx-click="sort" phx-target={@myself}>
      <%= @name %> <.chevron sorting={@sorting} key={@key} />
    </div>
    """
  end

  def handle_event("sort", _params, socket) do
    %{sorting: %{sort_dir: sort_dir, sort_by: prev_key}, key: key} =
      socket.assigns

    sort_dir =
      case {sort_dir, prev_key} do
        {:asc, ^key} -> :desc
        {:desc, ^key} -> :asc
        _ -> sort_dir
      end

    opts = %{sort_by: key, sort_dir: sort_dir}
    send(self(), {:update, opts})
    socket = assign(socket, :sorting, opts)
    {:noreply, socket}
  end

  def chevron(
        %{sorting: %{sort_by: key, sort_dir: _sort_dir}, key: key} = assigns
      ) do
    # TODO: Use an svg arrow
    ~H"""
    <%= if @sorting.sort_dir == :asc, do: "\u2191", else: "\u2193" %>
    """
  end

  def chevron(assigns), do: ~H""
end
