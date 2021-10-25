defmodule MarkevichMoney.OpenStartupTest do
  use MarkevichMoney.DataCase

  alias MarkevichMoney.OpenStartup

  describe "profits" do
    alias MarkevichMoney.OpenStartup.Profit

    @valid_attrs %{amount: "120.5", date: ~D[2021-04-22], description: "some description"}
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
      insert(:profit, %{amount: 10, date: ~D[2021-06-22]})
      insert(:profit, %{amount: 10, date: ~D[2021-06-12]})
      insert(:profit, %{amount: -10, date: ~D[2021-05-12]})

      [group1, group2] = OpenStartup.list_profits_grouped_by_month()

      assert group1.amount == Decimal.new(-10)
      assert group2.amount == Decimal.new(20)
    end

    test "list_incomes/0 returns list of positive profits" do
      _expense = insert(:profit, %{amount: -10, date: ~D[2021-10-12]})
      income = insert(:profit, %{amount: 10, date: ~D[2021-10-02]})

      assert OpenStartup.list_incomes() == [income]
    end

    test "list_expenses/0 returns list of negative profits" do
      expense = insert(:profit, %{amount: -10, date: ~D[2021-10-12]})
      _income = insert(:profit, %{amount: 10, date: ~D[2021-10-02]})

      assert OpenStartup.list_expenses() == [expense]
    end
  end

  describe ".list_popular_categories_by_month" do
    test "list_popular_categories_by_month/0 returns list of popular categories with counts" do
      food_category = insert(:transaction_category, %{name: "food_popular_category"})
      transport_category = insert(:transaction_category, %{name: "transport_popular_category"})
      home_category = insert(:transaction_category, %{name: "home_popular_category"})
      pet_category = insert(:transaction_category, %{name: "pet_popular_category"})
      other_category = insert(:transaction_category, %{name: "other_popular_category"})

      # speed up tests by reducing number of transaction user inserts.
      user = insert(:user)

      insert_list(5, :transaction,
        user: user,
        transaction_category: food_category,
        issued_at: ~N[2021-06-03 12:00:00]
      )

      insert_list(4, :transaction,
        user: user,
        transaction_category: transport_category,
        issued_at: ~N[2021-06-03 12:00:00]
      )

      insert_list(3, :transaction,
        user: user,
        transaction_category: home_category,
        issued_at: ~N[2021-06-03 12:00:00]
      )

      insert_list(2, :transaction,
        user: user,
        transaction_category: pet_category,
        issued_at: ~N[2021-06-03 12:00:00]
      )

      insert_list(1, :transaction,
        user: user,
        transaction_category: other_category,
        issued_at: ~N[2021-06-03 12:00:00]
      )

      insert_list(5, :transaction,
        user: user,
        transaction_category: pet_category,
        issued_at: ~N[2021-05-03 12:00:00]
      )

      insert_list(4, :transaction,
        user: user,
        transaction_category: home_category,
        issued_at: ~N[2021-05-03 12:00:00]
      )

      insert_list(3, :transaction,
        user: user,
        transaction_category: transport_category,
        issued_at: ~N[2021-05-03 12:00:00]
      )

      insert_list(2, :transaction,
        user: user,
        transaction_category: food_category,
        issued_at: ~N[2021-05-03 12:00:00]
      )

      insert_list(1, :transaction,
        user: user,
        transaction_category: other_category,
        issued_at: ~N[2021-05-03 12:00:00]
      )

      insert_list(5, :transaction,
        user: user,
        transaction_category: pet_category,
        issued_at: ~N[2021-03-03 12:00:00]
      )

      insert_list(4, :transaction,
        user: user,
        transaction_category: home_category,
        issued_at: ~N[2021-03-03 12:00:00]
      )

      insert_list(3, :transaction,
        user: user,
        transaction_category: transport_category,
        issued_at: ~N[2021-03-03 12:00:00]
      )

      insert_list(2, :transaction,
        user: user,
        transaction_category: food_category,
        issued_at: ~N[2021-03-03 12:00:00]
      )

      insert_list(1, :transaction,
        user: user,
        transaction_category: other_category,
        issued_at: ~N[2021-03-03 12:00:00]
      )

      records = OpenStartup.list_popular_categories_by_month()

      assert(
        records ==
          %{
            "food_popular_category" => [
              [
                %{
                  category_name: "food_popular_category",
                  date: ~D[2021-03-01],
                  records_count: 2
                }
              ],
              [
                %{
                  category_name: "food_popular_category",
                  date: ~D[2021-06-01],
                  records_count: 5
                },
                %{
                  category_name: "food_popular_category",
                  date: ~D[2021-05-01],
                  records_count: 2
                }
              ]
            ],
            "home_popular_category" => [
              [
                %{
                  category_name: "home_popular_category",
                  date: ~D[2021-03-01],
                  records_count: 4
                }
              ],
              [
                %{
                  category_name: "home_popular_category",
                  date: ~D[2021-06-01],
                  records_count: 3
                },
                %{
                  category_name: "home_popular_category",
                  date: ~D[2021-05-01],
                  records_count: 4
                }
              ]
            ],
            "pet_popular_category" => [
              [
                %{
                  category_name: "pet_popular_category",
                  date: ~D[2021-03-01],
                  records_count: 5
                }
              ],
              [
                %{
                  category_name: "pet_popular_category",
                  date: ~D[2021-06-01],
                  records_count: 2
                },
                %{
                  category_name: "pet_popular_category",
                  date: ~D[2021-05-01],
                  records_count: 5
                }
              ]
            ],
            "transport_popular_category" => [
              [
                %{
                  category_name: "transport_popular_category",
                  date: ~D[2021-03-01],
                  records_count: 3
                }
              ],
              [
                %{
                  category_name: "transport_popular_category",
                  date: ~D[2021-06-01],
                  records_count: 4
                },
                %{
                  category_name: "transport_popular_category",
                  date: ~D[2021-05-01],
                  records_count: 3
                }
              ]
            ]
          }
      )
    end
  end

  describe ".list_most_expensive_categories_by_month" do
    test "list_most_expensive_categories_by_month/0 returns list of most expensive categories with amounts" do
      food_category = insert(:transaction_category, %{name: "food_expensive_category"})
      transport_category = insert(:transaction_category, %{name: "transport_expensive_category"})
      home_category = insert(:transaction_category, %{name: "home_expensive_category"})
      pet_category = insert(:transaction_category, %{name: "pet_expensive_category"})
      other_category = insert(:transaction_category, %{name: "other_expensive_category"})

      # speed up tests by reducing number of transaction user inserts.
      user = insert(:user)

      insert(:transaction,
        user: user,
        transaction_category: food_category,
        issued_at: ~N[2021-06-14 12:00:00],
        amount: -10
      )

      insert(:transaction,
        user: user,
        transaction_category: transport_category,
        issued_at: ~N[2021-06-14 12:00:00],
        amount: -20
      )

      insert(:transaction,
        user: user,
        transaction_category: home_category,
        issued_at: ~N[2021-06-14 12:00:00],
        amount: -30
      )

      insert(:transaction,
        user: user,
        transaction_category: pet_category,
        issued_at: ~N[2021-06-14 12:00:00],
        amount: -40
      )

      insert(:transaction,
        user: user,
        transaction_category: other_category,
        issued_at: ~N[2021-06-14 12:00:00],
        amount: -5
      )

      insert(:transaction,
        user: user,
        transaction_category: food_category,
        issued_at: ~N[2021-05-14 12:00:00],
        amount: -40
      )

      insert(:transaction,
        user: user,
        transaction_category: transport_category,
        issued_at: ~N[2021-05-14 12:00:00],
        amount: -30
      )

      insert(:transaction,
        user: user,
        transaction_category: home_category,
        issued_at: ~N[2021-05-14 12:00:00],
        amount: -20
      )

      insert(:transaction,
        user: user,
        transaction_category: pet_category,
        issued_at: ~N[2021-05-14 12:00:00],
        amount: -10
      )

      insert(:transaction,
        user: user,
        transaction_category: other_category,
        issued_at: ~N[2021-05-14 12:00:00],
        amount: -5
      )

      insert(:transaction,
        user: user,
        transaction_category: food_category,
        issued_at: ~N[2021-03-14 12:00:00],
        amount: -40
      )

      insert(:transaction,
        user: user,
        transaction_category: transport_category,
        issued_at: ~N[2021-03-14 12:00:00],
        amount: -30
      )

      insert(:transaction,
        user: user,
        transaction_category: home_category,
        issued_at: ~N[2021-03-14 12:00:00],
        amount: -20
      )

      insert(:transaction,
        user: user,
        transaction_category: pet_category,
        issued_at: ~N[2021-03-14 12:00:00],
        amount: -10
      )

      insert(:transaction,
        user: user,
        transaction_category: other_category,
        issued_at: ~N[2021-03-14 12:00:00],
        amount: -5
      )

      records = OpenStartup.list_most_expensive_categories_by_month()

      assert(
        records ==
          %{
            "food_expensive_category" => [
              [
                %{
                  category_name: "food_expensive_category",
                  date: ~D[2021-03-01],
                  sum_amount: Decimal.new(40)
                }
              ],
              [
                %{
                  category_name: "food_expensive_category",
                  date: ~D[2021-06-01],
                  sum_amount: Decimal.new(10)
                },
                %{
                  category_name: "food_expensive_category",
                  date: ~D[2021-05-01],
                  sum_amount: Decimal.new(40)
                }
              ]
            ],
            "home_expensive_category" => [
              [
                %{
                  category_name: "home_expensive_category",
                  date: ~D[2021-03-01],
                  sum_amount: Decimal.new(20)
                }
              ],
              [
                %{
                  category_name: "home_expensive_category",
                  date: ~D[2021-06-01],
                  sum_amount: Decimal.new(30)
                },
                %{
                  category_name: "home_expensive_category",
                  date: ~D[2021-05-01],
                  sum_amount: Decimal.new(20)
                }
              ]
            ],
            "other_expensive_category" => [
              [
                %{
                  category_name: "other_expensive_category",
                  date: ~D[2021-03-01],
                  sum_amount: Decimal.new(5)
                }
              ],
              [
                %{
                  category_name: "other_expensive_category",
                  date: ~D[2021-06-01],
                  sum_amount: Decimal.new(5)
                },
                %{
                  category_name: "other_expensive_category",
                  date: ~D[2021-05-01],
                  sum_amount: Decimal.new(5)
                }
              ]
            ],
            "pet_expensive_category" => [
              [
                %{
                  category_name: "pet_expensive_category",
                  date: ~D[2021-03-01],
                  sum_amount: Decimal.new(10)
                }
              ],
              [
                %{
                  category_name: "pet_expensive_category",
                  date: ~D[2021-06-01],
                  sum_amount: Decimal.new(40)
                },
                %{
                  category_name: "pet_expensive_category",
                  date: ~D[2021-05-01],
                  sum_amount: Decimal.new(10)
                }
              ]
            ]
          }
      )
    end
  end
end
