defmodule MarkevichMoney.Priorbank.PriorbankConnection do
  use Ecto.Schema
  use MarkevichMoney.Constants

  import Ecto.Changeset

  alias __MODULE__
  alias MarkevichMoney.Users.User

  schema "priorbank_connections" do
    field :login, :string
    field :encrypted_password, :string

    field :client_secret, :string
    field :access_token, :string
    field :user_session, :string

    field :last_fetched_at, :utc_datetime

    belongs_to(:user, User)

    timestamps()
  end

  # def create_changeset(connection \\ %PriorbankConnection{}, attrs) do
  #   connection
  #   |> cast(attrs, [:login, :encrypted_password, :user_id])
  #   |> validate_required([:login, :encrypted_password, :user_id])
  # end

  def update_session_changeset(%PriorbankConnection{} = connection, attrs) do
    connection
    |> cast(attrs, [:client_secret, :access_token, :user_session])
    |> validate_required([:client_secret, :access_token, :user_session])
  end

  def update_last_fetched_at_changeset(%PriorbankConnection{} = connection, attrs) do
    connection
    |> cast(attrs, [:last_fetched_at])
    |> validate_required([:last_fetched_at])
  end
end
