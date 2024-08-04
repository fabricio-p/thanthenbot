defmodule ThanthenbotWeb.LogsLive do
  use ThanthenbotWeb, :live_view

  require Logger

  alias ThanthenbotWeb.LogsLive.{
    FilterComponent,
    PaginationComponent,
    SortingComponent
  }

  def mount(params, _session, socket) do
    socket = parse_params(socket, params)

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    dbg(params)
    socket =
      socket
      |> parse_params(params)
      |> assign_logs()

    {:noreply, socket}
  end

  def handle_info({:update, opts}, socket) do
    params = merge_sanitize_params(socket, opts)
    path = Routes.live_path(socket, __MODULE__, params)
    {:noreply, push_patch(socket, to: path, replace: true)}
  end

  defp format_date(%{date: date} = assigns) do
    string_value = to_string(date)
    split_pattern = :binary.compile_pattern([" ", "T"])
    [date_part, time_part] = String.split(string_value, split_pattern)

    assigns =
      assigns
      |> assign(:date_part, date_part)
      |> assign(:time_part, time_part)

    ~H"""
    <%= @date_part %><br /><%= @time_part %>
    """
  end

  defp parse_params(socket, params) do
    with {:ok, sorting_opts} <- SortingComponent.parse(params),
         {:ok, filter_opts} <- FilterComponent.parse(params) |> dbg(),
         {:ok, pagination_opts} <- PaginationComponent.parse(params) |> dbg() do
      socket
      |> assign_sorting(sorting_opts)
      |> assign_filter(filter_opts)
      |> assign_pagination(pagination_opts)
    else
      _error ->
        socket
        |> assign_sorting()
        |> assign_filter()
        |> assign_pagination()
    end
  end

  defp assign_sorting(socket, overrides \\ %{}) do
    opts = SortingComponent.default_values(overrides) |> dbg()
    assign(socket, :sorting, opts)
  end

  defp assign_filter(socket, overrides \\ %{}) do
    opts = FilterComponent.default_values(overrides) |> dbg()
    assign(socket, :filter, opts)
  end

  def assign_pagination(socket, overrides \\ %{}) do
    opts = PaginationComponent.default_values(overrides) |> dbg()
    assign(socket, :pagination, opts)
  end

  def merge_sanitize_params(socket, overrides \\ %{}) do
    %{sorting: sorting, filter: filter, pagination: pagination} = socket.assigns
    overrides = maybe_reset_pagination(overrides)

    %{}
    |> Map.merge(sorting)
    |> Map.merge(filter)
    |> Map.merge(pagination)
    |> Map.merge(overrides)
    |> Map.drop([:total_count])
    |> Enum.filter(fn {_key, value} -> value end)
    |> Map.new()
  end

  defp assign_logs(socket) do
    params = merge_sanitize_params(socket)
    # message_logs = Thanthenbot.list_messages(params)
    %{messages: message_logs, total_count: total_count} =
      Thanthenbot.list_messages_with_total_count(params)

    socket
    |> assign(:message_logs, message_logs)
    |> assign_total_count(total_count)
  end

  defp assign_total_count(socket, total_count) do
    update(socket, :pagination, fn pagination ->
      %{pagination | total_count: total_count}
    end)
  end

  def maybe_reset_pagination(overrides) do
    if FilterComponent.contains_filter_values?(overrides) do
      Map.put(overrides, :page, 1)
    else
      overrides
    end
  end
end
