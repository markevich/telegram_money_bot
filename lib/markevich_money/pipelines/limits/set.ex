defmodule MarkevichMoney.Pipelines.Limits.Set do
  use MarkevichMoney.Constants
  alias MarkevichMoney.{Gamifications, MessageData, Transactions}
  alias MarkevichMoney.Steps.Telegram.SendMessage

  @regex ~r/#{@limit_message}\s+(?<category_name>\D+)\s+(?<limit>\d+)/

  def call(%MessageData{message: @limit_message <> _rest} = message_data) do
    message_data
    |> Map.from_struct()
    |> parse_limits()
    |> render_message()
    |> SendMessage.call()
  end

  defp parse_limits(%{message: message} = payload) do
    result = Regex.named_captures(@regex, message)

    parsed_data = if result, do: result, else: %{}

    Map.put(payload, :parsed_data, parsed_data)
  end

  defp render_message(
         %{parsed_data: %{"category_name" => category_name, "limit" => limit}, current_user: user} =
           payload
       ) do
    category = Transactions.category_id_by_name(category_name)

    output_message =
      if category do
        Gamifications.set_transaction_category_limit!(category.id, user.id, limit)

        """
        На категорию #{category.name} установлен лимит #{limit}
        """
      else
        """
          Я не смог найти категорию #{category_name}.
          Список категорий для лимитов можно посмотреть с помощью команды #{@limits_message}
        """
      end

    Map.put(payload, :output_message, output_message)
  end

  defp render_message(%{parsed_data: %{}} = payload) do
    output_message = """
    Я не смог распознать эту команду

    Пример правильной команды:
    *#{@limit_message} Еда 150*
      - Еда - это *название* категории, которую можно подсмотреть с помощью команды #{
      @limits_message
    }
      - *150* - это целочисленное значение лимита
    """

    payload
    |> Map.put(:output_message, output_message)
  end
end
