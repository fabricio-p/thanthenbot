defmodule Thanthenbot.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "logged_messages" do
    field :author_id, :string
    field :message_id, :string
    field :guild_id, :string
    field :channel_id, :string
    field :content, :string
    field :author_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :author_id,
      :message_id,
      :guild_id,
      :channel_id,
      :content,
      :author_name
    ])
    |> validate_required([
      :author_id,
      :message_id,
      :guild_id,
      :channel_id,
      :content,
      :author_name
    ])
  end
end
