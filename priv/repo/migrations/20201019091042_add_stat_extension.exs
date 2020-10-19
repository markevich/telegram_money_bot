defmodule MarkevichMoney.Repo.Migrations.AddStatExtension do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION pg_stat_statements"
  end
end
