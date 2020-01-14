defmodule MarkevichMoney.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  schema "users" do
    field :name, :string
    field :telegram_chat_id, :integer

    timestamps()
  end
end
