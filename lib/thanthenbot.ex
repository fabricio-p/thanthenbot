defmodule Thanthenbot do
  @moduledoc """
  Thanthenbot keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  import Ecto.Query, warn: false
  require Logger
  alias Thanthenbot.Repo
  alias Thanthenbot.Message

  def list_messages(opts) do
    Logger.info(opts: opts)
    from(m in Message)
    |> sort(opts)
    |> Repo.all()
  end

  defp sort(query, %{sort_by: sort_by, sort_dir: sort_dir})
       when sort_by in [:id, :author_name, :guild_id, :channel_id] and
              sort_dir in [:asc, :desc] do
    order_by(query, {^sort_dir, ^sort_by})
  end

  defp sort(query, _opts), do: query
end
