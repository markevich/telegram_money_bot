defmodule MarkevichMoney.Bots.Pipeline do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pipelines" do
    timestamps()
  end

  @doc false
  def changeset(bot, attrs) do
    bot
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
