defmodule MarkevichMoney.Pipelines.Start do
  alias MarkevichMoney.Steps.Telegram.{SendMessage}

  @output_message "FIXME or REMOVEME"

  def call(payload) do
    payload
    |> Map.put(:output_message, @output_message)
    |> SendMessage.call()
  end
end
