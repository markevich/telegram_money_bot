defmodule MarkevichMoney.OpenStartupTest do
  use MarkevichMoney.DataCase

  alias MarkevichMoney.OpenStartup

  describe "profits" do
    alias MarkevichMoney.OpenStartup.Profit

    @valid_attrs %{amount: "120.5", date: ~D[2020-10-22], description: "some description"}
    @invalid_attrs %{amount: nil, date: nil}

    test "list_profits/0 returns all profits" do
      profit = insert(:profit, @valid_attrs)
      assert OpenStartup.list_profits() == [profit]
    end

    test "get_profit!/1 returns the profit with given id" do
      profit = insert(:profit, @valid_attrs)
      assert OpenStartup.get_profit!(profit.id) == profit
    end

    test "create_profit/1 with valid data creates a profit" do
      assert {:ok, %Profit{} = profit} = OpenStartup.create_profit(@valid_attrs)
      assert profit.amount == Decimal.new(@valid_attrs.amount)
      assert profit.description == @valid_attrs.description
    end

    test "create_profit/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = OpenStartup.create_profit(@invalid_attrs)
    end

    test "list_profits_grouped_by_month/0 returns grouped profits" do
      insert(:profit, %{amount: 10, date: ~D[2020-10-22]})
      insert(:profit, %{amount: 10, date: ~D[2020-10-12]})
      insert(:profit, %{amount: -10, date: ~D[2020-09-12]})

      [group1, group2] = OpenStartup.list_profits_grouped_by_month()

      assert group1.amount == Decimal.new(-10)
      assert group2.amount == Decimal.new(20)
    end

    test "list_incomes/0 returns list of positive profits" do
      _expense = insert(:profit, %{amount: -10, date: ~D[2020-10-22]})
      income = insert(:profit, %{amount: 10, date: ~D[2020-10-12]})

      assert OpenStartup.list_incomes() == [income]
    end

    test "list_expenses/0 returns list of negative profits" do
      expense = insert(:profit, %{amount: -10, date: ~D[2020-10-22]})
      _income = insert(:profit, %{amount: 10, date: ~D[2020-10-12]})

      assert OpenStartup.list_expenses() == [expense]
    end
  end
end
