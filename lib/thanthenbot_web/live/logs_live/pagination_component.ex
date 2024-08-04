defmodule ThanthenbotWeb.LogsLive.PaginationComponent do
  use ThanthenbotWeb, :live_component

  require Logger

  import Ecto.Changeset

  @fields %{
    page_number: :integer,
    page_size: :integer,
    total_count: :integer
  }

  @default_values %{
    page_number: 1,
    page_size: 20,
    total_count: 0
  }

  def parse(params, values \\ @default_values) do
    {values, @fields}
    |> cast(params, Map.keys(@fields))
    |> validate_number(:page_number, greater_than: 0)
    |> validate_number(:page_size, greater_than: 0)
    |> validate_number(:total_count, greater_than_or_equal_to: 0)
    |> apply_action(:insert)
  end

  def default_values(overrides \\ %{}) do
    Map.merge(@default_values, overrides)
  end

  def change_values(values \\ @default_values) do
    {values, @fields}
    |> cast(%{}, Map.keys(@fields))
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="pt-5">
        <%= for {page_number, current_page?} <- pages(@pagination |> dbg()) do %>
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
          :let={f}
          for={@pagination}
          as={:page_size_form}
          phx-change="set-page-size"
          phx-target={@myself}
        >
          <% dbg(f) %>
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
    parse_params(params |> dbg(), socket)
  end

  def update(%{pagination: pagination}, socket) do
    form =
      pagination
      |> change_values()
      |> to_form(as: :page_size_form)
      |> dbg()

    {:ok, assign(socket, :pagination, pagination)}
  end

  def parse_params(params, socket) do
    %{pagination: pagination} = socket.assigns

    case parse(params, pagination) do
      {:ok, opts} ->
        send(self(), {:update, opts})
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end
end
