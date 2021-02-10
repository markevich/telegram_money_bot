defmodule MarkevichMoney.Repo.Migrations.RemoveUsernameFromUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:name, :string)
    end
  end
end
