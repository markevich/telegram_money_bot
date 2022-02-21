defmodule MarkevichMoney.Transactions.Transaction do
  use Ecto.Schema
  use MarkevichMoney.Constants

  import Ecto.Changeset

  alias __MODULE__
  alias MarkevichMoney.Transactions.TransactionCategory
  alias MarkevichMoney.Users.User

  schema "transactions" do
    field :account, :string
    field :issued_at, :naive_datetime
    field :amount, :decimal
    field :external_amount, :decimal
    field :currency_code, :string
    field :external_currency, :string
    field :balance, :decimal
    field :to, :string
    field :lookup_hash, :string
    field :custom_description, :string
    field :temporary, :boolean

    field :status, Ecto.Enum,
      values: [
        @transaction_status_normal,
        @transaction_status_requires_confirmation,
        @transaction_status_bank_fund_freeze,
        @transaction_status_ignored
      ]

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
      :external_amount,
      :to,
      :account,
      :currency_code,
      :external_currency,
      :balance,
      :issued_at,
      :transaction_category_id,
      :lookup_hash,
      :user_id,
      :status
    ])
    |> upcase_currency_code
    |> validate_required([:user_id, :account, :amount, :issued_at, :status])
    |> validate_inclusion(:status, Ecto.Enum.values(__MODULE__, :status))
  end

  def update_after_upsert_changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :account,
      :issued_at,
      :amount,
      :external_amount,
      :currency_code,
      :external_currency,
      :balance,
      :to,
      :transaction_category_id,
      :custom_description,
      :status
    ])
    |> validate_required([:account, :issued_at, :amount, :currency_code, :balance, :to, :status])
    |> upcase_currency_code
    |> validate_inclusion(:status, Ecto.Enum.values(__MODULE__, :status))
  end

  defp upcase_currency_code(%Ecto.Changeset{valid?: true, changes: %{}} = changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{currency_code: currency_code}} ->
        put_change(changeset, :currency_code, String.upcase(currency_code))

      _ ->
        changeset
    end
  end

  def type(transaction) do
    case Decimal.compare(transaction.amount, 0) do
      :gt -> @transaction_type_income
      :lt -> @transaction_type_expense
      :eq -> @transaction_type_unknown
    end
  end
end
