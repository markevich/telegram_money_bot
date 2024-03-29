defmodule MarkevichMoney.Steps.Transaction.ParseAmountAndCurrencyTest do
  use MarkevichMoney.DataCase, async: true

  alias MarkevichMoney.Steps.Transaction.ParseAmountAndCurrency

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
      reply_payload = ParseAmountAndCurrency.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == 25.32)
      assert(reply_payload[:parsed_attributes][:currency_code] == "BYN")
      assert(reply_payload[:parsed_attributes][:external_amount] == nil)
      assert(reply_payload[:parsed_attributes][:external_currency] == nil)
    end

    @transaction_with_conversion """
    Карта 5.9737
    Со счёта: BY06ALFA30143400080030270000
    Оплата товаров/услуг
    Успешно
    Сумма:3 500.53 USD (7 200.04 BYN)
    Остаток:35 BYN
    На время:15:14:35
    ToFooBar
    28.01.2020 15:14:35
    """

    test "parses amount for converted transaction", default_payload do
      payload = Map.put(default_payload, :input_message, @transaction_with_conversion)
      reply_payload = ParseAmountAndCurrency.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == 7200.04)
      assert(reply_payload[:parsed_attributes][:currency_code] == "BYN")
      assert(reply_payload[:parsed_attributes][:external_amount] == 3500.53)
      assert(reply_payload[:parsed_attributes][:external_currency] == "USD")
    end

    @transaction_with_weird_spaces """
    Карта 5.9549
    Со счёта: BY82ALFA30146225550170270000
    Выдача наличных
    Успешно
    Сумма:1 600.00 BYN
    Остаток:661.93 BYN
    На время:15:35:11
    RECATMALF HO125 KRASN
    26.07.2023 15:35:10
    """

    test "parses amount for transaction with weird spaces in number", default_payload do
      payload = Map.put(default_payload, :input_message, @transaction_with_weird_spaces)
      reply_payload = ParseAmountAndCurrency.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == 1600)
      assert(reply_payload[:parsed_attributes][:currency_code] == "BYN")
    end
  end
end
