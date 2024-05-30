defmodule Thanthenbot.Repo.Migrations.CreateLoggedMessages do
  use Ecto.Migration

  def change do
    create table(:logged_messages) do
      add :author_id, :integer
      add :message_id, :integer
      add :guild_id, :integer
      add :channel_id, :integer
      add :message_content, :string

      timestamps(type: :utc_datetime)
    end
  end
end
