defmodule MarkevichMoney.MailgunProcessor do
  @behaviour Receivex.Handler

  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines

  def process(%Receivex.Email{} = mail) do
    input_message = mail.text
    [{_, to_email}] = mail.to
    [username, _rest] = String.split(to_email, "@")

    %MessageData{message: input_message, username: username} |> Pipelines.call
  end
end
