defmodule MarkevichMoney.Steps.Transaction.ParseAmountTest do
  use MarkevichMoney.DataCase, async: true

  alias MarkevichMoney.Steps.Transaction.ParseAmount

  describe ".call" do
    setup do
      default_payload = %{parsed_attributes: %{}}
      {:ok, default_payload}
    end

    @valid_transaction """
    Карта 5.9737
    Со счёта: BY06ALFA30143400080030270000
    Оплата товаров/услуг
    Успешно
    Сумма:25.32 BYN
    Остаток:35 BYN
    На время:15:14:35
    ToFooBar
    28.01.2020 15:14:35
    """

    test "parses amount", default_payload do
      payload = Map.put(default_payload, :input_message, @valid_transaction)
      reply_payload = ParseAmount.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == 25.32)
    end

    @transaction_with_conversion """
    Карта 5.9737
    Со счёта: BY06ALFA30143400080030270000
    Оплата товаров/услуг
    Успешно
    Сумма:3.53 USD (7.04 BYN)
    Остаток:35 BYN
    На время:15:14:35
    ToFooBar
    28.01.2020 15:14:35
    """

    test "parses amount for converted transaction", default_payload do
      payload = Map.put(default_payload, :input_message, @transaction_with_conversion)
      reply_payload = ParseAmount.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == 7.04)
    end
  end
end
