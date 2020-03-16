defmodule MarkevichMoney.UsersTest do
  use MarkevichMoney.DataCase, async: true

  alias MarkevichMoney.Users

  describe "#all_users" do
    setup do
      user1 = insert(:user)
      user2 = insert(:user)

      %{user1: user1, user2: user2}
    end

    test "returns all users", %{user1: user1, user2: user2} do
      result = Users.all_users()

      assert result == [user1, user2]
    end
  end
end
