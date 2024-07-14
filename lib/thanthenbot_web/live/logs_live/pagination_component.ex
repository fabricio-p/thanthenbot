defmodule ThanthenbotWeb.LogsLive.PaginationComponent do
  use ThanthenbotWeb, :live_component

  require Logger

  alias Thanthenbot.Forms.PaginationForm

  def render(assigns) do
    ~H"""
    <div>
      <div class="pt-5">
        <%= for {page_number, current_page?} <- pages(@pagination) do %>
          <div
            phx-click="show-page"
            phx-value-page_number={page_number}
            phx-target={@myself}
            class={[if(current_page?, do: "active bg-red-500"), "text-center"]}
          >
            <%= page_number %>
          </div>
        <% end %>
      </div>
      <div>
        <.form
          for={@pagination}
          as={:pagination}
          phx-change="set-page-size"
          phx-target={@myself}
        >
          <.input
            type="select"
            field={@pagination[:page_size]}
            options={[2, 5, 10, 20, 50, 100]}
            name="page_size"
            value={@pagination.page_size}
          />
        </.form>
      </div>
    </div>
    """
  end

  def mount(socket) do
    dbg(socket.assigns)
    {:ok, socket}
  end

  def pages(%{
        page_size: page_size,
        page_number: current_page,
        total_count: total_count
      }) do
    page_count = ceil(total_count / page_size)
    current_page = min(current_page, page_count)

    for page_number <- 1..page_count//1 do
      current_page? = page_number == current_page

      {page_number, current_page?}
    end
  end

  def handle_event("show-page", params, socket) do
    parse_params(params, socket)
  end

  def handle_event("set-page-size", params, socket) do
    parse_params(params, socket)
  end

  def update(%{pagination: pagination}, socket) do
    form =
      pagination
      |> dbg()
      |> PaginationForm.change_values()
      |> to_form(as: :pagination)

    {:ok, assign(socket, :pagination, pagination)}
  end

  def parse_params(params, socket) do
    %{pagination: pagination} = socket.assigns

    case PaginationForm.parse(params, pagination) do
      {:ok, opts} ->
        send(self(), {:update, opts})
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end
end
