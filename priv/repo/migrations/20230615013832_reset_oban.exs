defmodule MarkevichMoney.Repo.Migrations.ResetOban do
  use Ecto.Migration

  def up do
    drop_if_exists table(:oban_producers)
    Oban.Migrations.up(version: 11)
  end

  def down do
    # no way back
  end
end
