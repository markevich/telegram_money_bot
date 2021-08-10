defmodule MarkevichMoney.Gamification.Events.NewMonthStarted do
  use MarkevichMoney.Constants
  use MarkevichMoney.LoggerWithSentry

  use Oban.Worker, queue: :reports, max_attempts: 1

  alias MarkevichMoney.Gamification.Events.ReportSender
  alias MarkevichMoney.Users

  @impl Oban.Worker
  def perform(_job) do
    Users.all_users()
    |> Enum.each(fn user ->
      %{
        user_id: user.id
      }
      |> ReportSender.new()
      |> Oban.insert()
    end)

    :ok
  end
end
