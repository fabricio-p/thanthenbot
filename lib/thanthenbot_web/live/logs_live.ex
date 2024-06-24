defmodule ThanthenbotWeb.LogsLive do
  use ThanthenbotWeb, :live_view

  require Logger

  alias Thanthenbot.Forms.{SortingForm, FilterForm}

  def mount(params, _session, socket) do
    socket = parse_params(socket, params)

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
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
    with {:ok, sorting_opts} <- SortingForm.parse(params),
         {:ok, filter_opts} <- FilterForm.parse(params) do
      socket
      |> assign_sorting(sorting_opts)
      |> assign_filter(filter_opts)
    else
      _error ->
        socket
        |> assign_sorting()
        |> assign_filter()
    end
  end

  defp assign_sorting(socket, overrides \\ %{}) do
    opts = Map.merge(SortingForm.default_values(), overrides)
    assign(socket, :sorting, opts)
  end

  defp assign_filter(socket, overrides \\ %{}) do
    opts = FilterForm.default_values(overrides)
    assign(socket, :filter, opts)
  end

  def merge_sanitize_params(socket, overrides \\ %{}) do
    %{sorting: sorting, filter: filter} = socket.assigns

    %{}
    |> Map.merge(sorting)
    |> Map.merge(filter)
    |> Map.merge(overrides)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
    |> dbg()
  end

  defp assign_logs(socket) do
    params = merge_sanitize_params(socket)
    message_logs = Thanthenbot.list_messages(params)
    assign(socket, :message_logs, message_logs)
  end
end
