defmodule MarkevichMoney.Repo.Migrations.DropObanBeats do
  use Ecto.Migration

  def up do
    drop_if_exists table("oban_beats")
  end

  def down do
    # No going back!
  end
end
