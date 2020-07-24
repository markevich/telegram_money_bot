defmodule MarkevichMoney.Users do
  alias MarkevichMoney.Repo

  alias MarkevichMoney.Users.User

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

  def upsert_user!(attrs) do
    get_user_by_chat_id(attrs[:telegram_chat_id]) ||
      User.create_changeset(attrs)
      |> Repo.insert!()
  end
end
