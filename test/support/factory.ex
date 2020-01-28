defmodule MarkevichMoney.Factory do
  use ExMachina.Ecto, repo: MarkevichMoney.Repo

  def user_factory do
    %MarkevichMoney.Users.User{
      name: sequence(:name, &"username_#{&1}"),
      telegram_chat_id: sequence(:telegram_chat_id, & &1)
    }
  end

  def transaction_factory do
    %MarkevichMoney.Transactions.Transaction{
      account: "BY06ALFA30143400080030270000",
      datetime: DateTime.utc_now(),
      amount: Decimal.new(-100),
      currency_code: "BYN",
      balance: "1000",
      target: "Pizza",
      lookup_hash: Ecto.UUID.generate()
    }
  end

  def transaction_category_factory do
    %MarkevichMoney.Transactions.TransactionCategory{
      name: sequence(:name, &"category#{&1}")
    }
  end

  def transaction_category_prediction_factory do
    %MarkevichMoney.Transactions.TransactionCategoryPrediction{}
  end
end
