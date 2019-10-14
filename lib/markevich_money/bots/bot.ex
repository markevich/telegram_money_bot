defmodule MarkevichMoney.Bots.Bot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bots" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(bot, attrs) do
    bot
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
