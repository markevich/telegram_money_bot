defmodule MarkevichMoney.Users.User do
  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :telegram_chat_id, :integer

    timestamps()
  end
end
