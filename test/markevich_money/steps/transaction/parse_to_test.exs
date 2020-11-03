defmodule MarkevichMoney.Steps.Transaction.ParseToTest do
  use MarkevichMoney.DataCase, async: true

  alias MarkevichMoney.Steps.Transaction.ParseTo

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
    Сумма:25.32 byn
    Остаток:35 byn
    На время:15:14:35
    ToFooBar
    28.01.2020 15:14:35
    """

    @belavia_transaction """
    Карта 4.0000
    Со счёта: BY51ALFA401430391Z0010870000
    Комиссия за Альфа-Белавиа
    Успешно
    Сумма:4.90 BYN
    03.11.2020
    """

    test "parses amount", default_payload do
      payload = Map.put(default_payload, :input_message, @valid_transaction)
      reply_payload = ParseTo.call(payload)

      assert(reply_payload[:parsed_attributes][:to] == "ToFooBar")
    end

    test "parses belavia transaction", default_payload do
      payload = Map.put(default_payload, :input_message, @belavia_transaction)
      reply_payload = ParseTo.call(payload)

      assert(reply_payload[:parsed_attributes][:to] == "Комиссия за Альфа-Белавиа")
    end
  end
end
