defmodule MarkevichMoney.OpenStartup.Profit do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:amount, :description, :inserted_at]}

  schema "profits" do
    field :amount, :decimal
    field :description, :string
    field :date, :date

    timestamps()
  end

  @doc false
  def changeset(profit, attrs) do
    profit
    |> cast(attrs, [:amount, :date, :description])
    |> validate_required([:amount, :date])
  end
end
