defmodule MarkevichMoney.Steps.Transaction.ParseCustomTransactionMessageTest do
  @moduledoc false
  use MarkevichMoney.Constants
  use MarkevichMoney.DataCase, async: true
  use Oban.Pro.Testing, repo: MarkevichMoney.Repo
  alias MarkevichMoney.Steps.Transaction.ParseCustomTransactionMessage

  describe "Valid messages" do
    test "All valid variants should pass validation" do
      assert(
        ParseCustomTransactionMessage.valid_message?("#{@add_message} 50.23 фрукты на рынке")
      )

      assert(
        ParseCustomTransactionMessage.valid_message?("#{@add_message} фрукты на рынке 50.23")
      )
    end
  end

  describe "Generic numbers and spaces regex rules" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    test "Happy path with normal data", %{user: user} do
      message = "#{@add_message} 50.23 фрукты на рынке"

      result =
        ParseCustomTransactionMessage.call(%{
          message: message,
          current_user: user
        })

      parsed_attributes = result.parsed_attributes

      assert parsed_attributes.amount == -50.23
      assert parsed_attributes.to == "фрукты на рынке"
      assert parsed_attributes.account == @manual_account
      assert parsed_attributes.currency_code == "BYN"
      assert parsed_attributes.balance == 0
      assert parsed_attributes.issued_at
      assert parsed_attributes.lookup_hash
      assert parsed_attributes.user_id == user.id
    end

    test "When number with comma", %{user: user} do
      message = "#{@add_message} 50,23 фрукты на рынке"

      result =
        ParseCustomTransactionMessage.call(%{
          message: message,
          current_user: user
        })

      parsed_attributes = result.parsed_attributes

      assert parsed_attributes.amount == -50.23
      assert parsed_attributes.to == "фрукты на рынке"
      assert parsed_attributes.account == @manual_account
      assert parsed_attributes.currency_code == "BYN"
      assert parsed_attributes.balance == 0
      assert parsed_attributes.issued_at
      assert parsed_attributes.lookup_hash
      assert parsed_attributes.user_id == user.id
    end

    test "With exceeded spaces", %{user: user} do
      message = "#{@add_message}  50.23  фрукты на рынке"

      result =
        ParseCustomTransactionMessage.call(%{
          message: message,
          current_user: user
        })

      parsed_attributes = result.parsed_attributes

      assert parsed_attributes.amount == -50.23
      assert parsed_attributes.to == "фрукты на рынке"
      assert parsed_attributes.account == @manual_account
      assert parsed_attributes.currency_code == "BYN"
      assert parsed_attributes.balance == 0
      assert parsed_attributes.issued_at
      assert parsed_attributes.lookup_hash
      assert parsed_attributes.user_id == user.id
    end
  end
end
