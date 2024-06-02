defmodule Thanthenbot.Repo.Migrations.CreateLoggedMessages do
  use Ecto.Migration

  def change do
    create table(:logged_messages) do
      add :author_id, :string
      add :message_id, :string
      add :guild_id, :string
      add :channel_id, :string
      add :content, :string
      add :author_name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
