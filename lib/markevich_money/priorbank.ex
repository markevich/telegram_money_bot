defmodule MarkevichMoney.Priorbank do
  alias MarkevichMoney.Priorbank.Auth
  alias MarkevichMoney.Priorbank.PriorbankConnection
  alias MarkevichMoney.Repo
  alias MarkevichMoney.Steps.Telegram.SendMessage
  alias MarkevichMoney.Steps.Transaction.RenderTransaction
  alias MarkevichMoney.Transactions
  alias MarkevichMoney.Workers.CreateTransaction

  def go(connection) do
    connection
    |> Auth.get_transactions()
    |> add_new_transactions(connection.user)

    connection
    |> PriorbankConnection.update_last_fetched_at_changeset(%{last_fetched_at: DateTime.utc_now()})
    |> Repo.update!()
  end

  def add_new_transactions(api_response, user) do
    transactions_attributes = extract_transactions_attributes(api_response)

    Enum.map(transactions_attributes, fn attributes ->
      attributes = Map.put(attributes, :user_id, user.id)

      %{transaction_attributes: attributes, source: :priorbank}
      |> CreateTransaction.new()
      |> Oban.insert()
    end)
  end

  def extract_transactions_attributes(api_response) do
    byn_accounts = select_byn_accounts(api_response)

    Enum.reduce(byn_accounts, [], fn account, acc ->
      blocked_transactions = select_blocked_transactions(account) |> Enum.reverse()
      regular_transactions = select_regular_transactions(account) |> Enum.reverse()

      acc = acc ++ convert_blocked_transactions(blocked_transactions)
      acc ++ convert_regular_transactions(regular_transactions)
    end)
  end

  def select_byn_accounts(data) do
    data["result"]
    |> Enum.filter(fn info ->
      get_in(info, ["contract", "contractCurrIso"]) == "BYN"
    end)
  end

  def select_blocked_transactions(data) do
    get_in(data, ["contract", "abortedContractList"])
    |> Enum.flat_map(fn account ->
      account["abortedTransactionList"]
    end)
  end

  def select_regular_transactions(data) do
    get_in(data, ["contract", "account", "transCardList"])
    |> Enum.flat_map(fn account ->
      account["transactionList"]
    end)
  end

  def convert_blocked_transactions(blocked_transactions) do
    Enum.map(blocked_transactions, fn transaction ->
      amount = -transaction["amount"]
      issued_at = generate_date_time(transaction["transDate"], transaction["transTime"])

      attributes = %{
        account: "BYN cards",
        amount: amount,
        currency_code: "BYN",
        balance: "0",
        issued_at: issued_at,
        to: transaction["transDetails"] |> cleanup_to()
      }

      if transaction["transCurrIso"] != "BYN" do
        attributes
        |> Map.put(:external_amount, -transaction["transAmount"])
        |> Map.put(:external_currency, transaction["transCurrIso"])
      else
        attributes
      end
    end)
  end

  def convert_regular_transactions(regular_transactions) do
    Enum.map(regular_transactions, fn transaction ->
      amount = transaction["accountAmount"]
      issued_at = generate_date_time(transaction["transDate"], transaction["transTime"])

      attributes = %{
        account: "BYN cards",
        amount: amount,
        currency_code: "BYN",
        balance: "0",
        issued_at: issued_at,
        to: transaction["transDetails"] |> cleanup_to()
      }

      if transaction["transCurrIso"] != "BYN" do
        attributes
        |> Map.put(:external_amount, transaction["amount"])
        |> Map.put(:external_currency, transaction["transCurrIso"])
      else
        attributes
      end
    end)
  end

  defp generate_date_time(date, time) do
    date_with_time = String.replace(date, "00:00:00", time)
    NaiveDateTime.from_iso8601!(date_with_time)
  end

  defp cleanup_to(target) do
    String.replace(target, ~r/(Retail\s)|(CH\sPayment\s)|(CH\sDebit\s)/, "")
    |> String.trim()
  end
end
