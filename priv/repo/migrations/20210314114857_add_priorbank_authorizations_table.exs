defmodule MarkevichMoney.Repo.Migrations.AddPriorbankAuthorizationsTable do
  use Ecto.Migration

  def change do
    create table(:priorbank_connections) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :login, :string, null: false
      add :encrypted_password, :string, null: false
      add :access_token, :text
      add :user_session, :text
      add :client_secret, :text
      add :last_fetched_at, :utc_datetime, null: false, default: fragment("now()")

      timestamps()
    end

    create index(:priorbank_connections, [:user_id])
  end
end
