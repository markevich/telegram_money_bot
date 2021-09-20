defmodule MarkevichMoney.Sleeper do
  # TODO: That is obviosly a hack. Remove it once oban will support smart rate limiting.
  def sleep(duration \\ 1000) do
    Process.sleep(duration)
  end
end
