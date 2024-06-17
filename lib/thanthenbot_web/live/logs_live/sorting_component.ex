defmodule ThanthenbotWeb.LogsLive.SortingComponent do
  use ThanthenbotWeb, :live_component

  attr :id, :string
  attr :name, :string, required: true
  attr :key, :atom, required: true
  attr :sorting, :map, required: true

  def render(assigns) do
    ~H"""
    <div phx-click="sort" phx-target={@myself}>
      <%= @name %> <%= chevron(@sorting, @key) %>
    </div>
    """
  end

  def handle_event("sort", _params, socket) do
    %{sorting: %{sort_dir: sort_dir}, key: key} = socket.assigns
    sort_dir = if sort_dir == :asc, do: :desc, else: :asc
    opts = %{sort_by: key, sort_dir: sort_dir}
    send(self(), {:update, opts})
    {:noreply, assign(socket, :sorting, opts)}
  end

  def chevron(opts, key) do
    IO.inspect(opts, label: :opts)
    IO.inspect(key, label: :key)
    _chevron(opts, key)
  end

  def _chevron(%{sort_by: sort_by, sort_dir: sort_dir}, key)
      when sort_by == key do
  if sort_dir == :asc, do: "↑", else: "↓"
  end

  def _chevron(_opts, _key), do: ""
end
