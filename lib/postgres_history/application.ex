defmodule PostgresHistory.Application do
  use Application

  def start(_type, _args) do
    children = [
      PostgresHistory.Repo,
      PostgresHistory.CreateHistory
    ]

    opts = [strategy: :one_for_one, name: PostgresHistory.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
