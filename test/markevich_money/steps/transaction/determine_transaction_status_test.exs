defmodule MarkevichMoney.Steps.Transaction.DetermineTransactionStatusTest do
  use MarkevichMoney.DataCase, async: true

  alias MarkevichMoney.Steps.Transaction.DetermineTransactionStatus

  describe ".call with normal transaction" do
    setup do
      normal_transaction_message = """
        Карта 5.9737
        Со счёта: BY06ALFA30143400080030270000
        Оплата товаров/услуг
        Успешно
        Сумма:25.32 byn
        Остаток:35 byn
        На время:15:14:35
        ToFooBar
        28.01.2020 15:14:35
      """

      default_payload = %{parsed_attributes: %{}}

      {:ok, default_payload: default_payload, message: normal_transaction_message}
    end

    test "returns normal status", context do
      payload = Map.put(context.default_payload, :input_message, context.message)
      reply_payload = DetermineTransactionStatus.call(payload)

      assert(reply_payload[:parsed_attributes][:status] == :normal)
    end
  end

  describe ".call with money transfer transaction" do
    setup do
      unconfirmed_transaction_message = """
        Карта 5.9737
        Со счёта: BY06ALFA30143400080030270000
        Оплата товаров/услуг
        Успешно
        Сумма:25.32 byn
        Остаток:35 byn
        На время:15:14:35
        BLR/ONLINE SERVICE/TRANSFERS AK AM
        28.01.2020 15:14:35
      """

      default_payload = %{parsed_attributes: %{}}

      {:ok, default_payload: default_payload, message: unconfirmed_transaction_message}
    end

    test "returns requires_confirmation status", context do
      payload = Map.put(context.default_payload, :input_message, context.message)
      reply_payload = DetermineTransactionStatus.call(payload)

      assert(reply_payload[:parsed_attributes][:status] == :requires_confirmation)
    end
  end

  describe ".call with money exchange transaction" do
    setup do
      income_transaction_message = """
        Карта 5.9737
        На счёт: BY06TEST
        Перевод (Поступление)
        Успешно
        Сумма:25.32 BYN
        Остаток:30 BYN
        На время:15:14:35
        BLR/ONLINE SERVICE/TRANSFERS AK AM
        28.01.2020 15:14:355
      """

      default_payload = %{parsed_attributes: %{amount: 25.32}}

      {:ok, default_payload: default_payload, message: income_transaction_message}
    end

    test "returns normal status", context do
      payload = Map.put(context.default_payload, :input_message, context.message)
      reply_payload = DetermineTransactionStatus.call(payload)

      assert(reply_payload[:parsed_attributes][:status] == :normal)
    end
  end
end
