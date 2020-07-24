defmodule MarkevichMoney.Repo.Migrations.AddUserRegistration do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :notification_email, :string, null: true
    end
    create unique_index(:users, [:notification_email])
  end
end
