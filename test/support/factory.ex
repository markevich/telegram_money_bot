defmodule MarkevichMoney.Factory do
  use ExMachina.Ecto, repo: MarkevichMoney.Repo

  def user_factory do
    %MarkevichMoney.Users.User{
      telegram_chat_id: sequence(:telegram_chat_id, & &1),
      notification_email: sequence(:notification_emaill, &"email#{&1}")
    }
  end

  def transaction_factory do
    %MarkevichMoney.Transactions.Transaction{
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
    %MarkevichMoney.Transactions.TransactionCategory{
      name: sequence(:name, &"category#{&1}"),
      transaction_category_folder: build(:transaction_category_folder)
    }
  end

  def transaction_category_folder_factory do
    %MarkevichMoney.Transactions.TransactionCategoryFolder{
      name: sequence(:name, &"folder_#{&1}"),
      has_single_category: true
    }
  end

  def transaction_category_limit_factory do
    %MarkevichMoney.Gamification.TransactionCategoryLimit{
      user: build(:user),
      transaction_category: build(:transaction_category),
      limit: 100
    }
  end

  def profit_factory do
    %MarkevichMoney.OpenStartup.Profit{
      date: DateTime.utc_now(),
      amount: 100,
      description: "description"
    }
  end

  def priorbank_connection_factory do
    %MarkevichMoney.Priorbank.PriorbankConnection{
      login: sequence(:login, &"connection-#{&1}"),
      encrypted_password: sequence(:encrypted_password, &"password-#{&1}"),
      client_secret: "client_secret",
      access_token: "access_token",
      user_session: "user_session",
      last_fetched_at: DateTime.utc_now(),
      user: build(:user)
    }
  end
end
