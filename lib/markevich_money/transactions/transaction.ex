defmodule MarkevichMoney.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  schema "transactions" do
    field :account, :string
    field :datetime, :naive_datetime
    field :amount, :decimal
    field :currency_code, :string
    field :balance, :decimal
    field :target, :string
    field :type, :string

    field :status, :string

    timestamps()
  end

  @doc false
  def create_changeset(transaction \\ %Transaction{}) do
    transaction
    |> cast(%{}, [])
    |> put_change(:status, "initial")
  end

  def update_changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:account, :datetime, :amount, :currency_code, :balance, :target, :type])
    |> validate_required([:account, :datetime, :amount, :currency_code, :balance, :target, :type])
  end
end
