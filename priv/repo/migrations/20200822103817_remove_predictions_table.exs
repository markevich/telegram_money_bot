defmodule MarkevichMoney.Repo.Migrations.RemovePredictionsTable do
  use Ecto.Migration

  def change do
    drop table(:transaction_category_prediction)
  end
end
