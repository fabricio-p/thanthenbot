defmodule Thanthenbot do
  @moduledoc """
  Thanthenbot keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @sortable_keys [:id, :author_name, :guild_id, :channel_id, :inserted_at]
  @sort_directions [:asc, :desc]

  import Ecto.Query, warn: false

  require Logger

  alias Thanthenbot.Repo
  alias Thanthenbot.Message

  def list_messages(opts) do
    Logger.info(opts: opts)

    from(m in Message)
    |> sort(opts)
    |> filter(opts)
    |> Repo.all()
  end

  defp sort(query, %{sort_by: sort_by, sort_dir: sort_dir})
       when sort_by in @sortable_keys and
              sort_dir in @sort_directions do
    order_by(query, {^sort_dir, ^sort_by})
  end

  defp sort(query, _opts), do: query

  defp filter(query, opts) do
    query
    |> filter_by_id(opts)
    |> filter_by_author_name(opts)
    |> filter_by_guild_id(opts)
    |> filter_by_channel_id(opts)
  end

  defp filter_by_id(query, %{id: id}) when is_integer(id) do
    where(query, id: ^id)
  end

  defp filter_by_id(query, _opts), do: query

  defp filter_by_author_name(query, %{author_name: name})
       when is_binary(name) and name != "" do
    query_string = "%#{name}%"
    where(query, [m], ilike(m.author_name, ^query_string))
  end

  defp filter_by_author_name(query, _opts), do: query

  defp filter_by_guild_id(query, %{guild_id: guild_id}) do
    where(query, id: ^guild_id)
  end

  defp filter_by_guild_id(query, _opts), do: query

  defp filter_by_channel_id(query, %{channel_id: channel_id}) do
    where(query, id: ^channel_id)
  end

  defp filter_by_channel_id(query, _opts), do: query
end
