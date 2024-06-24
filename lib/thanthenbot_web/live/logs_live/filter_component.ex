defmodule ThanthenbotWeb.LogsLive.FilterComponent do
  use ThanthenbotWeb, :live_component

  require Logger

  alias Thanthenbot.Forms.FilterForm

  attr :show_form, :boolean, default: true

  def render(assigns) do
    ~H"""
    <div class="w-1/3 mb-5 flex flex-col items-center">
      <.button phx-click="search-toggle" phx-target={@myself}>
        Toggle Search
      </.button>
      <.form
        :if={@show_form}
        for={@form}
        as={:filter}
        phx-submit="search"
        phx-target={@myself}
        class="flex items-center flex-col w-full"
      >
        <div class="grid grid-cols-2 grid-rows-2 gap-4">
          <.input type="number" field={@form[:id]} label="ID" class="bg-teal-500" />
          <.input type="text" field={@form[:author_name]} label="Author" />
          <.input
            type="number"
            field={@form[:guild_id]}
            label="Guild ID"
            minlength={19}
            maxlength={19}
            autocomplete="off"
          />
          <.input
            type="number"
            field={@form[:channel_id]}
            label="Channel ID"
            minlength={19}
            maxlength={19}
            autocomplete="off"
          />
        </div>
        <.button
          type="submit"
          class="
              mx-auto my-2
              p-2
              bg-sky-600/90
            "
        >
          <span class="text-white">Search</span>
        </.button>
      </.form>
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, :show_form, false)}
  end

  def update(%{filter: filter}, socket) do
    form =
      filter
      |> FilterForm.change_values()
      |> to_form(as: :filter)

    {:ok, assign(socket, :form, form)}
  end

  def handle_event("search-toggle", _, socket) do
    {:noreply, socket}
    {:noreply, assign(socket, :show_form, not socket.assigns[:show_form])}
  end

  def handle_event("search", %{"filter" => filter}, socket) do
    case FilterForm.parse(filter) do
      {:ok, opts} ->
        send(self(), {:update, opts})
        {:noreply, socket}

      {:error, changeset} ->
        errors =
          changeset
          |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
            Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
              opts
              |> Keyword.get(String.to_existing_atom(key), key)
              |> to_string()
            end)
          end)
          |> Enum.to_list()

        form = to_form(filter, as: :filter, errors: errors)
        socket = assign(socket, :form, form)
        {:noreply, socket}
    end
  end
end
