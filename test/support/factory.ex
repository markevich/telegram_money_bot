defmodule MarkevichMoney.Factory do
  use ExMachina.Ecto, repo: MarkevichMoney.Repo

  def user_factory do
    %MarkevichMoney.Users.User{
      name: sequence(:name, &"username_#{&1}"),
      telegram_chat_id: sequence(:telegram_chat_id, & &1)
    }
  end
end
