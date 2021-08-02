defmodule MarkevichMoney.Gamification.Events.EndOfTheMonthBroadcaster do
  use MarkevichMoney.Constants
  use MarkevichMoney.LoggerWithSentry
  alias MarkevichMoney.Gamification.Events.EndOfTheMonthListener

  use Oban.Worker, queue: :events, max_attempts: 2

  @impl Oban.Worker
  def perform(_job) do
    Users.all_users()
    |> Enum.map(fn user ->
      %{
        user_id: user.id
      }
      |> LimitTracker.new()
      |> Oban.insert()
    end)

    :ok
  end

  defp listeners do
    []
  end
end
