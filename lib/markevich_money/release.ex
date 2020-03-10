defmodule MarkevichMoney.Release do

  @current_version Mix.Project.config[:version]
  def send_changelog! do
    @current_version
    |> changelog()
    |> send_to_all_users()
  end

  def changelog("0.1.3") do
    """
    🔥🔥🔥🔥🔥🔥🔥

    MoneyBot updated to version `0.1.3` 🍾🍾

      New:
        - Added integration with https://sentry.io. Errors shall not pass!! [GH#15](https://github.com/markevich/markevich_money/issues/15)
    """
  end
  def changelog("0.1.2") do
    """
    🔥🔥🔥🔥🔥🔥🔥

    MoneyBot updated to version `0.1.2` 🍾🍾

      Fixes:
        - Reduce padding for category statistics table
    """
  end
  def changelog("0.1.1") do
    """
    MoneyBot updated to version `0.1.1` 🍾🍾

      New:
        - Implement statistic by categories. Click /stats to explore. [GH#10](https://github.com/markevich/markevich_money/issues/10)
        - Implement automated release log sender. [GH#13](https://github.com/markevich/markevich_money/issues/13)

      Fixes:
        - Fixed float numbers rounding. There should be no numbers like `1.4e3` anymore
    """
  end

  def old do
    message = """
    ```
    New bot version released! Changes:

    - Fix datetime parsing for values without time
    - Add remaining tests. Coverage is 100\% now
    - Add test coverage for creating a transaction from manual input
    - Exclude unrelevant files from coverage calculation
    - Add test coverage for /add command
    - Add emoji to categories
    - Apply mix formatter
    - Add test coverage for /start message
    - Add test coverage to /help pipeline
    - Add test coverage for setting the current user in callbacks
    - Add test coverage for set_category pipeline
    - Add test coverage for stats callbacks pipeline
    - Add test coverage for choose_category pipeline
    - Add tests for mailgun receiver
    - Fix account regexp
    - Update elixir packages
    - Update npm packages
    ```
    """

    MarkevichMoney.Steps.Telegram.SendMessage.call(%{
      output_message: message,
      chat_id: 133_501_152
    })
  end

  defp send_to_all_users(message) do
    MarkevichMoney.Users.all_users()
    |> Enum.each(fn user ->
      MarkevichMoney.Steps.Telegram.SendMessage.call(%{
        output_message: message,
        chat_id: user.telegram_chat_id
      })
    end)
  end
end
