defmodule MarkevichMoney.Users.User do
  alias __MODULE__

  import Ecto.Changeset

  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :telegram_chat_id, :integer
    field :notification_email, :string

    timestamps()
  end

  def create_changeset(attrs) do
    %User{}
    |> cast(attrs, [:name, :telegram_chat_id, :email_uuid])
    |> put_change(:notification_email, String.slice(Ecto.UUID.generate(), 0, 8))
    |> validate_required([:name, :telegram_chat_id, :email_uuid])

    # |> unique_constraint(:email_uuid)
  end

  defp notification_email do
    "tg.money.bot+#{String.slice(Ecto.UUID.generate(), 0, 8)}"
  end
end
