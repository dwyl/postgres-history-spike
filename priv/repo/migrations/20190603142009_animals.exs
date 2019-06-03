defmodule PostgresHistory.Repo.Migrations.Animals do
  use Ecto.Migration

  def change do
    create table(:animals) do
      add(:name, :string)
      add(:species, :string)
    end
  end
end
