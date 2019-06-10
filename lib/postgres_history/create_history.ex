defmodule PostgresHistory.CreateHistory do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(args) do
    create_history()
    {:ok, args}
  end

  def create_history do
    repo = repo()
    db_name = database()

    "/Users/robertfrancis/Code/work/postgres-history-spike/sql"
    |> File.ls!()
    |> Enum.map(&File.read!("/Users/robertfrancis/Code/work/postgres-history-spike/sql/#{&1}"))
    |> Enum.each(&Ecto.Adapters.SQL.query!(repo, &1))

    Ecto.Adapters.SQL.query!(repo, "SELECT create_history('#{db_name}')")
  end

  defp repo do
    :postgres_history
    |> Application.fetch_env!(PostgresHistory.CreateHistory)
    |> Keyword.fetch!(:repo)
  end

  defp database do
    :postgres_history
    |> Application.fetch_env!(PostgresHistory.CreateHistory)
    |> Keyword.fetch!(:database)
  end
end
