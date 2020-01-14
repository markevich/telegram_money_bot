defmodule MarkevichMoney.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias MarkevichMoney.Transactions.TransactionCategory
  alias MarkevichMoney.Users.User

  schema "transactions" do
    field :account, :string
    field :datetime, :naive_datetime
    field :amount, :decimal
    field :currency_code, :string
    field :balance, :decimal
    field :target, :string
    field :type, :string
    field :lookup_hash, :string

    field :status, :string

    belongs_to(:transaction_category, TransactionCategory)
    belongs_to(:user, User)

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
    |> cast(attrs, [
      :account,
      :datetime,
      :amount,
      :currency_code,
      :balance,
      :target,
      :type,
      :transaction_category_id
    ])
    |> validate_required([:account, :datetime, :amount, :currency_code, :balance, :target, :type])
  end
end
