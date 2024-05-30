defmodule Thanthenbot.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "logged_messages" do
    field :message_content, :string
    field :author_id, :integer
    field :message_id, :integer
    field :guild_id, :integer
    field :channel_id, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:author_id, :message_id, :guild_id, :channel_id, :message_content])
    |> validate_required([:author_id, :message_id, :guild_id, :channel_id, :message_content])
  end
end
