defmodule Thanthenbot.Forms.SortingForm do
  import Ecto.Changeset

  alias Thanthenbot.EctoHelper

  @sort_by_variants [:id, :author_name, :guild_id, :channel_id, :inserted_at]
  @sort_dir_variants [:asc, :desc]

  @fields %{
    sort_by: EctoHelper.enum(@sort_by_variants),
    sort_dir: EctoHelper.enum(@sort_dir_variants)
  }
  @default_values %{
    sort_by: :id,
    sort_dir: :asc
  }

  def parse(params) do
    {@default_values, @fields}
    |> cast(params, Map.keys(@fields))
    |> apply_action(:insert)
  end

  def default_values(overrides \\ %{}) do
    Map.merge(@default_values, overrides)
  end

  # def variants(:sort_by), do: @sort_by_variants
  # def variants(:sort_dir), do: @sort_dir_variants
end
