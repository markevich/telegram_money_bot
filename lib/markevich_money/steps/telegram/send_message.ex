defmodule MarkevichMoney.Steps.Telegram.SendMessage do
  use MarkevichMoney.LoggerWithSentry

  def call(callback_data) do
    call(callback_data, [])
  end

  def call(
        %{output_message: output_message, reply_markup: reply_markup, current_user: current_user} =
          payload,
        additional_options
      )
      when not is_nil(current_user) do
    options =
      [
        reply_markup: reply_markup,
        parse_mode: "Markdown"
      ]
      |> Keyword.merge(additional_options)

    Nadia.send_message(current_user.telegram_chat_id, output_message, options)
    |> process_result(payload)
  end

  def call(
        %{output_message: output_message, current_user: current_user} = payload,
        additional_options
      )
      when not is_nil(current_user) do
    options =
      [
        parse_mode: "Markdown"
      ]
      |> Keyword.merge(additional_options)

    Nadia.send_message(current_user.telegram_chat_id, output_message, options)
    |> process_result(payload)
  end

  def call(
        %{output_message: output_message, reply_markup: reply_markup, chat_id: chat_id} = payload,
        additional_options
      ) do
    options =
      [
        reply_markup: reply_markup,
        parse_mode: "Markdown"
      ]
      |> Keyword.merge(additional_options)

    Nadia.send_message(chat_id, output_message, options)
    |> process_result(payload)
  end

  def call(%{output_message: output_message, chat_id: chat_id} = payload, additional_options) do
    options =
      [
        parse_mode: "Markdown"
      ]
      |> Keyword.merge(additional_options)

    Nadia.send_message(chat_id, output_message, options)
    |> process_result(payload)
  end

  def process_result(result, payload) do
    case result do
      {:ok, _result} ->
        payload

      {:error, %Nadia.Model.Error{reason: "Forbidden: bot was blocked by the user"} = reason} ->
        log_error_message(
          """
          Bot was blocked by the user.
          """,
          %{
            payload: payload,
            reason: reason
          }
        )

        payload

      {:error, %Nadia.Model.Error{reason: "Forbidden: user is deactivated"} = reason} ->
        log_error_message(
          """
          Telegram user is deactivated.
          """,
          %{
            payload: payload,
            reason: reason
          }
        )

        payload

      {:error, %Nadia.Model.Error{reason: "Bad Request: chat not found"} = reason} ->
        log_error_message(
          """
          Telegram user no longer exists.
          """,
          %{
            payload: payload,
            reason: reason
          }
        )

        payload

      {:error, other_reason} ->
        log_error_message(
          """
          Received unknown response from nadia.
          """,
          %{
            payload: payload,
            reason: other_reason
          }
        )

        raise RuntimeError, message: other_reason
    end
  end
end
