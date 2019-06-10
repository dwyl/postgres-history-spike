defmodule RequireHistory.Repo do
  use Ecto.Repo,
    otp_app: :require_history,
    adapter: Ecto.Adapters.Postgres
end
