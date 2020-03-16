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
    field :to, :string
    field :lookup_hash, :string

    belongs_to(:transaction_category, TransactionCategory)
    belongs_to(:user, User)

    timestamps()
  end

  @doc false
  def create_changeset(transaction \\ %Transaction{}, attrs) do
    transaction
    |> cast(attrs, [
      :account,
      :amount,
      :to,
      :account,
      :currency_code,
      :balance,
      :datetime,
      :transaction_category_id,
      :lookup_hash,
      :user_id
    ])
  end

  def update_changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :account,
      :datetime,
      :amount,
      :currency_code,
      :balance,
      :to,
      :transaction_category_id
    ])
    |> validate_required([:account, :datetime, :amount, :currency_code, :balance, :to])
  end
end
