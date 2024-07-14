defmodule Thanthenbot.Forms.PaginationForm do
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
end
