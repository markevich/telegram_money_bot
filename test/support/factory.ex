defmodule TelegramMoneyBot.Factory do
  use ExMachina.Ecto, repo: TelegramMoneyBot.Repo

  def user_factory do
    %TelegramMoneyBot.Users.User{
      name: sequence(:name, &"username_#{&1}"),
      telegram_chat_id: sequence(:telegram_chat_id, & &1)
    }
  end

  def transaction_factory do
    %TelegramMoneyBot.Transactions.Transaction{
      account: "BY06ALFA30143400080030270000",
      issued_at: DateTime.utc_now(),
      amount: Decimal.new(-100),
      currency_code: "BYN",
      balance: "1000",
      to: "Pizza",
      lookup_hash: Ecto.UUID.generate(),
      user: build(:user)
    }
  end

  def transaction_category_factory do
    %TelegramMoneyBot.Transactions.TransactionCategory{
      name: sequence(:name, &"category#{&1}")
    }
  end

  def transaction_category_limit_factory do
    %TelegramMoneyBot.Gamification.TransactionCategoryLimit{
      user: build(:user),
      transaction_category: build(:transaction_category),
      limit: 100
    }
  end
end
