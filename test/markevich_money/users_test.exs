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

  describe "#get_user_by_token!" do
    test "returns user with same token" do
      token = Ecto.UUID.generate()

      original_user = insert(:user, api_token: token)

      user = Users.get_user_by_token!(token)

      assert(original_user.id == user.id)
    end
  end
end
