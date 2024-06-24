defmodule Thanthenbot.Forms.FilterForm do
  import Ecto.Changeset

  @fields %{
    id: :integer,
    author_name: :string,
    guild_id: :string,
    channel_id: :string
  }

  @default_values %{
    id: nil,
    author_name: nil,
    guild_id: nil,
    channel_id: nil
  }

  def default_values(overrides \\ %{}) do
    Map.merge(@default_values, overrides)
  end

  def parse(params) do
    {@default_values, @fields}
    |> cast(params, Map.keys(@fields))
    |> validate_number(:id, greater_than_or_equal_to: 1)
    |> validate_length(:guild_id, is: 19)
    |> validate_length(:channel_id, is: 19)
    |> apply_action(:insert)
  end

  def change_values(values \\ @default_values) do
    {values, @fields}
    |> cast(%{}, Map.keys(@fields))
  end
end
