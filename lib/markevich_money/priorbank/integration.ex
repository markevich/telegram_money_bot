defmodule MarkevichMoney.Priorbank.Integration do
  use MarkevichMoney.Constants

  alias MarkevichMoney.Priorbank.Api
  alias MarkevichMoney.Priorbank.PriorbankConnection
  alias MarkevichMoney.Repo

  def fetch_priorbank_transactions(connection) do
    connection
    |> maybe_update_session()
    |> Api.get_cards_details()
  end

  def convert_to_readable_transaction_attributes(api_response) do
    byn_accounts = select_byn_accounts(api_response)

    Enum.reduce(byn_accounts, [], fn account, acc ->
      blocked_transactions = select_blocked_transactions(account) |> Enum.reverse()
      regular_transactions = select_regular_transactions(account) |> Enum.reverse()

      acc = acc ++ convert_blocked_transactions(blocked_transactions)
      acc ++ convert_regular_transactions(regular_transactions)
    end)
  end

  def update_last_fetched_at!(connection) do
    connection
    |> PriorbankConnection.update_last_fetched_at_changeset(%{last_fetched_at: DateTime.utc_now()})
    |> Repo.update!()
  end

  defp select_byn_accounts(data) do
    data["result"]
    |> Enum.filter(fn info ->
      get_in(info, ["contract", "contractCurrIso"]) == "BYN"
    end)
  end

  defp select_blocked_transactions(data) do
    get_in(data, ["contract", "abortedContractList"])
    |> Enum.flat_map(fn account ->
      account["abortedTransactionList"]
    end)
  end

  defp select_regular_transactions(data) do
    get_in(data, ["contract", "account", "transCardList"])
    |> Enum.flat_map(fn account ->
      account["transactionList"]
    end)
  end

  defp convert_blocked_transactions(blocked_transactions) do
    Enum.map(blocked_transactions, fn transaction ->
      amount = -transaction["amount"]
      issued_at = generate_date_time(transaction["transDate"], transaction["transTime"])

      attributes = %{
        account: "BYN cards",
        amount: amount,
        currency_code: "BYN",
        balance: "0",
        issued_at: issued_at,
        to: transaction["transDetails"] |> cleanup_to(),
        status: @transaction_status_bank_fund_freeze
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

  defp convert_regular_transactions(regular_transactions) do
    Enum.map(regular_transactions, fn transaction ->
      amount = transaction["accountAmount"]
      issued_at = generate_date_time(transaction["transDate"], transaction["transTime"])

      attributes = %{
        account: "BYN cards",
        amount: amount,
        currency_code: "BYN",
        balance: "0",
        issued_at: issued_at,
        to: transaction["transDetails"] |> cleanup_to(),
        status: @transaction_status_normal
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

  defp maybe_update_session(session) do
    login = session.login
    encrypted_password = session.encrypted_password

    if Api.authenticated?(session) do
      session
    else
      {:ok, new_tokens} = Api.authenticate(login, encrypted_password)

      update_session!(session, new_tokens)
    end
  end

  defp update_session!(
         old_session,
         %{
           client_secret: _client_secret,
           access_token: _access_token,
           user_session: _user_session
         } = attrs
       ) do
    old_session
    |> PriorbankConnection.update_session_changeset(attrs)
    |> Repo.update!()
  end
end
