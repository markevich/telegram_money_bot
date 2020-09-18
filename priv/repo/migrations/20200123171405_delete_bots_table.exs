defmodule TelegramMoneyBot.Repo.Migrations.DeleteBotsTable do
  use Ecto.Migration

  def change do
    drop table(:bots)
  end
end
