defmodule MarkevichMoney.ProgressBarTest do
  use MarkevichMoney.DataCase, async: true
  alias MarkevichMoney.ProgressBar

  describe ".call" do
    test "when percentage < 100" do
      result = ProgressBar.call(30, 100, "BYN")

      expected = """
      ```
      |⣿⣿⣿⣿⣿⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀|
           30% (30/100) BYN
      ```
      """

      assert(result == expected)
    end

    test "when percentage > 100" do
      result = ProgressBar.call(130, 100, "BYN")

      expected = """
      ```
      |⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿|
          130% (130/100) BYN
      ```
      """

      assert(result == expected)
    end

    test "when numbers are large" do
      result = ProgressBar.call(13_000_000, 25_000_000, "BYN")

      expected = """
      ```
      |⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀|
      52% (13000000/25000000) BYN
      ```
      """

      assert(result == expected)
    end
  end
end
