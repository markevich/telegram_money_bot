defmodule MarkevichMoney.Repo.Migrations.UpgradeObanJobsToV10 do
  use Ecto.Migration

  def up do
    Oban.Migrations.up(version: 10)
  end

  def down do
    Oban.Migrations.down(version: 9)
  end
end
