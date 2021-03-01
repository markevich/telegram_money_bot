defmodule MarkevichMoney.Pipelines.EditDescription do
  alias MarkevichMoney.Steps.Transaction.RenderTransaction
  alias MarkevichMoney.Transactions

  alias MarkevichMoney.Steps.Telegram.SendMessage

  @transaction_id_regex ~r/Транзакция\s№(?<transaction_id>\d+)/u
  def call(payload) do
    maybe_update_transaction_description(payload)
    |> SendMessage.call()
  end

  def maybe_update_transaction_description(payload) do
    with {:ok, transaction_id} <- extract_transaction_id_from_message(payload.reply_to_message),
         {:ok, transaction} <- fetch_transaction(transaction_id, payload.current_user),
         {:ok, transaction} <- update_transaction_description(transaction, payload.message),
         updated_payload <- render_transaction(transaction, payload) do
      updated_payload
    else
      {:invalid_format} ->
        error_message = """
        Что-то пошло не так, бот не смог распознать твой ответ. Возможно, ответ был отправлен не на сообщение с транзакцией, а на какой-то иной текст, из-за чего и произошла ошибка.
        """

        Map.put(payload, :output_message, error_message)
    end
  end

  def extract_transaction_id_from_message(message) do
    captures = Regex.named_captures(@transaction_id_regex, message)

    case captures do
      %{"transaction_id" => transaction_id} ->
        {:ok, transaction_id}

      _other ->
        {:invalid_format}
    end
  end

  def fetch_transaction(transaction_id, user) do
    transaction = Transactions.get_user_transaction!(transaction_id, user.id)

    {:ok, transaction}
  end

  def update_transaction_description(transaction, new_description) do
    transaction
    |> Transactions.update_transaction(%{custom_description: new_description})
  end

  def render_transaction(transaction, payload) do
    payload
    |> Map.put(:transaction, transaction)
    |> RenderTransaction.call()
  end
end
