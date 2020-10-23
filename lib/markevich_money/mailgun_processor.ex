defmodule MarkevichMoney.MailgunProcessor do
  @behaviour Receivex.Handler

  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines

  def process(%Receivex.Email{} = mail) do
    input_message = mail.text
    [{_, to_email}] = mail.to
    [notification_email, _rest] = String.split(to_email, "@")

    %MessageData{message: input_message, notification_email: notification_email}
    |> Pipelines.call()

    :ok
  end
end
