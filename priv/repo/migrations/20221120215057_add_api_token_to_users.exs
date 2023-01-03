defmodule MarkevichMoney.Repo.Migrations.AddApiTokenToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :api_token, :string, null: true
    end
  end
end
