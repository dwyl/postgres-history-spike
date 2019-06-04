defmodule RequireHistory.Application do
  use Application

  def start(_type, _args) do
    children = [
      RequireHistory.Repo,
      RequireHistoryWeb.Endpoint,
      PostgresHistory.CreateHistory
    ]

    opts = [strategy: :one_for_one, name: RequireHistory.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    RequireHistoryWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
