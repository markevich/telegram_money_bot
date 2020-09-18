defmodule TelegramMoneyBot.Users do
  alias TelegramMoneyBot.Repo

  alias TelegramMoneyBot.Users.User

  import Ecto.Query, only: [from: 2]

  def get_user!(id) do
    Repo.get!(User, id)
  end

  def get_user_by_chat_id(chat_id) do
    Repo.one(from u in User, where: u.telegram_chat_id == ^chat_id)
  end

  def get_user_by_chat_id!(chat_id) do
    Repo.one!(from u in User, where: u.telegram_chat_id == ^chat_id)
  end

  def get_user_by_username(username) do
    Repo.one(from u in User, where: u.name == ^String.downcase(username))
  end

  def all_users do
    Repo.all(User)
  end
end
