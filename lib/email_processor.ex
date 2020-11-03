defmodule EmailProcessor do
  # TODO: write tests. I can't even imagine amount of mocks that i need to write to test that code.
  # Does it make sense?
  alias MarkevichMoney.MessageData
  alias MarkevichMoney.Pipelines

  use MarkevichMoney.LoggerWithSentry
  use Oban.Worker, queue: :mail_fetcher, max_attempts: 1

  @impl Oban.Worker
  def perform(payload) do
    call()

    {:ok, payload}
  end

  def call do
    client = connect!()
    {:ok, {total_count, _total_size}} = :epop_client.stat(client)

    if total_count > 0 do
      1..total_count |> Enum.each(&retreive_and_send_to_pipeline(client, &1))
    end

    :epop_client.quit(client)
  end

  defp retreive_and_send_to_pipeline(client, index) do
    {:ok, mail_content} = :epop_client.bin_retrieve(client, index)

    case get_to_and_body(mail_content) do
      [email, nil] -> log_error_message("Received email without body for #{email}")
      [email, body] -> send_message_to_pipeline(email, body)
    end
  end

  defp send_message_to_pipeline(email, body) do
    [notification_email, _rest] = String.split(email, "@")

    try do
      %MessageData{message: body, notification_email: notification_email}
      |> Pipelines.call()
    rescue
      e ->
        log_exception(e, __STACKTRACE__, %{message: body, notification_email: notification_email})
    end
  end

  defp get_to_and_body(mail) do
    {:message, header_list, body_content} = :epop_message.bin_parse(mail)

    to_email = Pop3mail.header_lookup(header_list, "To")

    part_list = Pop3mail.decode_body_content(header_list, body_content)

    text_part =
      Enum.find(part_list, fn part ->
        part.media_type == "text/plain"
      end)

    if text_part do
      [to_email, text_part.content]
    else
      [to_email, nil]
    end
  end

  defp connect! do
    opts = Application.get_env(:markevich_money, :pop3_receiver)

    username = String.to_charlist(opts[:username])
    password = String.to_charlist(opts[:password])

    {:ok, client} =
      :epop_client.connect(username, password, [
        :ssl,
        {:addr, 'pop.gmail.com'},
        {:port, 995},
        {:user, username}
      ])

    client
  end
end
