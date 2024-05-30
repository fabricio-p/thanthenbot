defmodule Thanthenbot.Repo do
  use Ecto.Repo,
    otp_app: :thanthenbot,
    adapter: Ecto.Adapters.Postgres
end
