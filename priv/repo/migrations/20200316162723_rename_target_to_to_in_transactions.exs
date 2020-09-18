defmodule TelegramMoneyBot.Repo.Migrations.RenameTargetToToInTransactions do
  use Ecto.Migration

  def change do
    rename table(:transactions), :target, to: :to
  end
end
