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

    payload
    |> send_message(current_user.telegram_chat_id, output_message, options)
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

    payload
    |> send_message(current_user.telegram_chat_id, output_message, options)
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

    payload
    |> send_message(chat_id, output_message, options)
  end

  def call(%{output_message: output_message, chat_id: chat_id} = payload, additional_options) do
    options =
      [
        parse_mode: "Markdown"
      ]
      |> Keyword.merge(additional_options)

    payload
    |> send_message(chat_id, output_message, options)
  end

  def process_result(result, payload) do
    case result do
      {:ok, _result} ->
        payload

      {:error, %Nadia.Model.Error{reason: "Forbidden: bot was blocked by the user"}} ->
        log_error_message(
          """
          Bot was blocked by the user.
          """,
          %{
            payload: payload
          }
        )

        payload

      {:error, %Nadia.Model.Error{reason: "Forbidden: user is deactivated"}} ->
        log_error_message(
          """
          Telegram user is deactivated.
          """,
          %{
            payload: payload
          }
        )

        payload

      {:error, %Nadia.Model.Error{reason: "Bad Request: chat not found"}} ->
        log_error_message(
          """
          Telegram user no longer exists.
          """,
          %{
            payload: payload
          }
        )

        payload

      {:error, %Nadia.Model.Error{reason: "Forbidden: the group chat was deleted"}} ->
        log_error_message(
          """
          The group chat was deleted.
          """,
          %{
            payload: payload
          }
        )

        payload

      {:error, other_reason} ->
        raise RuntimeError, message: other_reason
    end
  end

  @telegram_limit 4096
  defp send_message(payload, chat_id, output_message, options) do
    # Telegram has a limit when sending message of 4096 chars
    if String.length(output_message) > @telegram_limit do
      {left_part, right_part} = {
        String.slice(output_message, 0, @telegram_limit),
        String.slice(output_message, @telegram_limit..String.length(output_message))
      }

      [part_to_move, left_part] =
        left_part
        |> String.reverse()
        |> String.split("\n", parts: 2)

      left_part = String.reverse(left_part) <> "\n"
      right_part = String.reverse(part_to_move) <> right_part

      default_markdown_option = [parse_mode: "Markdown"]
      Nadia.send_message(chat_id, left_part, default_markdown_option) |> process_result(payload)
      Nadia.send_message(chat_id, right_part, options) |> process_result(payload)
    else
      Nadia.send_message(chat_id, output_message, options)
      |> process_result(payload)
    end
  end
end
