defmodule PostgresHistory.CreateHistory do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, "postgres_history_dev")
  end

  def init(db_name) do
    create_history(db_name)
    {:ok, db_name}
  end

  defp create_history(db_name) do
    "sql"
    |> File.ls!()
    |> Enum.map(&File.read!("sql/#{&1}"))
    |> Enum.each(&Ecto.Adapters.SQL.query!(PostgresHistory.Repo, &1))

    Ecto.Adapters.SQL.query!(PostgresHistory.Repo, "SELECT create_history('#{db_name}')")
  end
end