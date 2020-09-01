defmodule MarkevichMoney.Pipelines.Limits.Set do
  use MarkevichMoney.Constants
  alias MarkevichMoney.Gamifications
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Steps.Telegram.SendMessage

  @regex ~r/#{@set_limit_message}\s+(?<category_id>\d+)\s+(?<limit>\d+)/
  def call(%MessageData{message: @set_limit_message <> _rest} = message_data) do
    message_data
    |> Map.from_struct()
    |> parse_limits()
    |> render_message()
    |> SendMessage.call()
  end

  defp parse_limits(%{message: message} = payload) do
    result = Regex.named_captures(@regex, message)

    parsed_data =
      case result do
        nil ->
          %{}

        %{"category_id" => category_id, "limit" => limit} ->
          %{category_id: category_id, limit: limit}
      end

    payload
    |> Map.put(:parsed_data, parsed_data)
  end

  defp render_message(
         %{parsed_data: %{category_id: category_id, limit: limit}, current_user: user} = payload
       ) do
    Gamifications.set_transaction_category_limit!(category_id, user.id, limit)

    output_message = """
    Упешно!

    Нажмите на #{@limits_message} для просмотра обновленных лимитов
    """

    payload
    |> Map.put(:output_message, output_message)
  end

  defp render_message(%{parsed_data: %{}} = payload) do
    output_message = """
    Я не смог распознать эту команду

    Пример правильной команды:
    *#{@set_limit_message} 1 150*
      - *1* это *id* категории, которую можно подсмотреть с помощью команды #{@limits_message}
      - *150* это целочисленное значение лимита
    """

    payload
    |> Map.put(:output_message, output_message)
  end
end
