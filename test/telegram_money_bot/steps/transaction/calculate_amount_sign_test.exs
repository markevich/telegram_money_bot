defmodule TelegramMoneyBot.Steps.Transaction.CalculateAmountSignTest do
  use TelegramMoneyBot.DataCase, async: true

  alias TelegramMoneyBot.Steps.Transaction.CalculateAmountSign

  describe ".call" do
    setup do
      default_payload = %{parsed_attributes: %{amount: 25.32}}
      {:ok, default_payload}
    end

    @outcome_transaction """
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

    test "Negate the amount", default_payload do
      payload = Map.put(default_payload, :input_message, @outcome_transaction)
      reply_payload = CalculateAmountSign.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == -25.32)
    end

    @income_transaction """
    Карта 5.9737
    На счёт: BY06ALFA30143400080030270000
    Перевод (Поступление)
    Успешно
    Сумма:25.32 byn
    Остаток:30 byn
    На время:15:14:35
    ToFooBar
    28.01.2020 15:14:355
    """

    test "does not change amount sign", default_payload do
      payload = Map.put(default_payload, :input_message, @income_transaction)
      reply_payload = CalculateAmountSign.call(payload)

      assert(reply_payload[:parsed_attributes][:amount] == 25.32)
    end
  end
end
