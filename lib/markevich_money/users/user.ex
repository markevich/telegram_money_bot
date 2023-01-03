defmodule MarkevichMoney.Users.User do
  alias __MODULE__

  import Ecto.Changeset

  use Ecto.Schema

  schema "users" do
    field :telegram_chat_id, :integer
    field :notification_email, :string
    field :api_token, :string

    timestamps()
  end

  def create_changeset(attrs) do
    %User{}
    |> cast(attrs, [:telegram_chat_id])
    |> put_change(:notification_email, notification_email())
    |> validate_required([:telegram_chat_id, :notification_email])
    |> unique_constraint(:notification_email)
  end

  defp notification_email do
    "tg.money.bot+#{String.slice(Ecto.UUID.generate(), 0, 12)}"
  end
end
