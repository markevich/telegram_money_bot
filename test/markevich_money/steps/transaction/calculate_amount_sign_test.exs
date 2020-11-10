defmodule MarkevichMoney.Steps.Transaction.CalculateAmountSignTest do
  use MarkevichMoney.DataCase, async: true

  alias MarkevichMoney.Steps.Transaction.CalculateAmountSign

  describe ".call with single currency" do
    setup do
      default_payload = %{parsed_attributes: %{amount: 25.32}}
      {:ok, default_payload}
    end

    @outcome_transaction """
    Карта 5.9737
    Со счёта: BY06TEST
    Оплата товаров/услуг
    Успешно
    Сумма:25.32 BYN
    Остаток:35 BYN
    На время:15:14:35
    ToFooBar
    28.01.2020 15:14:35
    """

    test "Negate the amount", default_payload do
      payload = Map.put(default_payload, :input_message, @outcome_transaction)
      reply_payload = CalculateAmountSign.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == -25.32)
    end

    @income_transaction """
    Карта 5.9737
    На счёт: BY06TEST
    Перевод (Поступление)
    Успешно
    Сумма:25.32 BYN
    Остаток:30 BYN
    На время:15:14:35
    ToFooBar
    28.01.2020 15:14:355
    """

    test "does not change amount sign", default_payload do
      payload = Map.put(default_payload, :input_message, @income_transaction)
      reply_payload = CalculateAmountSign.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == 25.32)
    end

    @refund_transaction """
    Карта 4.2174
    Со счёта: BY03TEST
    Оплата товаров/услуг(возврат)
    Успешно
    Сумма:25.32 BYN
    Остаток:30 BYN
    На время:15:38:19
    RUS/MOSCOW/YANDEX.HEALTH
    29.10.2020 15:38:18
    """

    test "Marks as income for a refund", default_payload do
      payload = Map.put(default_payload, :input_message, @refund_transaction)
      reply_payload = CalculateAmountSign.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == 25.32)
    end

    @deposit_transaction """
    Карта 5.8959
    Со счёта: BY33ALFA32143374660180270000
    Внесение наличных
    Успешно
    Сумма:25.32 BYN
    Остаток:256.60 BYN
    На время:16:35:13
    BLR/MINSK/RECATMALF HO83 PORT
    09.11.2020 16:35:03
    """

    test "Marks as income for a deposit", default_payload do
      payload = Map.put(default_payload, :input_message, @deposit_transaction)
      reply_payload = CalculateAmountSign.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == 25.32)
    end
  end

  describe ".call with double currency" do
    setup do
      default_payload = %{parsed_attributes: %{amount: 25.32, external_amount: 11.32}}
      {:ok, default_payload}
    end

    @outcome_transaction """
    Карта 5.9737
    Со счёта: BY06TEST
    Оплата товаров/услуг
    Успешно
    Сумма:11.32 USD (25.32 BYN)
    Остаток:35 BYN
    На время:15:14:35
    ToFooBar
    28.01.2020 15:14:35
    """

    test "Negate the amount", default_payload do
      payload = Map.put(default_payload, :input_message, @outcome_transaction)
      reply_payload = CalculateAmountSign.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == -25.32)
      assert(reply_payload[:parsed_attributes][:external_amount] == -11.32)
    end

    @income_transaction """
    Карта 5.9737
    На счёт: BY06TEST
    Перевод (Поступление)
    Успешно
    Сумма:11.32USD (25.32 BYN)
    Остаток:30 BYN
    На время:15:14:35
    ToFooBar
    28.01.2020 15:14:355
    """

    test "does not change amount sign", default_payload do
      payload = Map.put(default_payload, :input_message, @income_transaction)
      reply_payload = CalculateAmountSign.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == 25.32)
      assert(reply_payload[:parsed_attributes][:external_amount] == 11.32)
    end

    @refund_transaction """
    Карта 4.2174
    Со счёта: BY03TEST
    Оплата товаров/услуг(возврат)
    Успешно
    Сумма:11.32 USD (25.32 BYN)
    Остаток:30 BYN
    На время:15:38:19
    RUS/MOSCOW/YANDEX.HEALTH
    29.10.2020 15:38:18
    """

    test "Marks as income for a refund", default_payload do
      payload = Map.put(default_payload, :input_message, @refund_transaction)
      reply_payload = CalculateAmountSign.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == 25.32)
      assert(reply_payload[:parsed_attributes][:external_amount] == 11.32)
    end
  end
end
