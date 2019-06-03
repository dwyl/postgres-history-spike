defmodule PostgresHistory.Repo do
  use Ecto.Repo,
    otp_app: :postgres_history,
    adapter: Ecto.Adapters.Postgres
end
