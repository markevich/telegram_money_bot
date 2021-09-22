defmodule MarkevichMoney.Pipelines.Reports.MonthlyReport.ComparedExpensesTest do
  use MarkevichMoney.DataCase, async: true

  alias MarkevichMoney.Pipelines.Reports.MonthlyReport.ComparedExpenses
  alias MarkevichMoney.Transactions

  describe "call" do
    setup do
      from1 = ~N[2021-07-01 00:00:00]
      to1 = ~N[2021-08-01 00:00:00]
      issued_at1 = ~N[2021-07-05 00:00:00]

      from2 = ~N[2021-08-01 01:00:00]
      to2 = ~N[2021-09-01 00:00:00]
      issued_at2 = ~N[2021-08-05 00:00:00]

      home_folder =
        insert(:transaction_category_folder, name: "Home folder", has_single_category: false)

      home_category1 =
        insert(:transaction_category, name: "Home 1", transaction_category_folder: home_folder)

      food_folder =
        insert(:transaction_category_folder, name: "Food folder", has_single_category: false)

      food_category1 =
        insert(:transaction_category, name: "Food 1", transaction_category_folder: food_folder)

      food_category2 =
        insert(:transaction_category, name: "Food 2", transaction_category_folder: food_folder)

      sport_folder =
        insert(:transaction_category_folder, name: "Sport folder", has_single_category: true)

      sport_category =
        insert(:transaction_category, name: "Sport", transaction_category_folder: sport_folder)

      bills_category = insert(:transaction_category, name: "Bills")
      home_category = insert(:transaction_category, name: "Home")
      pets_category = insert(:transaction_category, name: "Pets")

      user = insert(:user)

      # month 1
      insert(:transaction,
        amount: "-10",
        transaction_category: food_category1,
        issued_at: issued_at1,
        user: user
      )

      insert(:transaction,
        amount: "100",
        transaction_category: food_category1,
        issued_at: issued_at1,
        user: user
      )

      insert(:transaction,
        amount: "-5",
        transaction_category: food_category1,
        issued_at: issued_at1,
        user: user
      )

      insert(:transaction,
        amount: "-20",
        transaction_category: food_category2,
        issued_at: issued_at1,
        user: user
      )

      insert(:transaction,
        amount: "-10",
        transaction_category: food_category2,
        issued_at: issued_at1,
        user: user
      )

      # month 2
      insert(:transaction,
        amount: "-30",
        transaction_category: food_category1,
        issued_at: issued_at2,
        user: user
      )

      #

      insert(:transaction,
        amount: "-40",
        transaction_category: sport_category,
        issued_at: issued_at2,
        user: user
      )

      insert(:transaction,
        amount: "-50",
        transaction_category: bills_category,
        issued_at: issued_at2,
        user: user
      )

      insert(:transaction,
        amount: "-60",
        transaction_category: home_category,
        issued_at: issued_at1,
        user: user
      )

      insert(:transaction, amount: "-100", transaction_category: pets_category, user: user)

      insert(:transaction,
        amount: "-150",
        transaction_category: home_category1,
        issued_at: issued_at1,
        user: user
      )

      %{
        user: user,
        from1: from1,
        to1: to1,
        from2: from2,
        to2: to2,
        issued_at1: issued_at1,
        issued_at2: issued_at2,
        pets_category: pets_category
      }
    end

    test "returns rendered table", context do
      stats1 =
        Transactions.stats(
          context.user,
          context.from1,
          context.to1
        )

      stats2 =
        Transactions.stats(
          context.user,
          context.from2,
          context.to2
        )

      result = ComparedExpenses.call(stats1, "Month 1", stats2, "Month 2")

      assert(
        result.output_message == """
        Переверни телефон в альбомный режим для лучшей читабельности!
        ```

                Сравнение расходов

        Категория   Month 1 Month 2 Разница

        Bills       0       50      🔴+50

        Sport       0       40      🔴+40

        Food folder 45      30      🟢-15
        ├Food 1     15      30      🔴+15
        └Food 2     30      0       🟢-30

        Home        60      0       🟢-60

        Home folder
        └Home 1     150     0       🟢-150



        Подведем итоги:

        Month 1 - 255 золотых.
        Month 2 - 120 золотых.
        ```
        """
      )
    end

    test "returns correct persentage diff and numeric diff for the less spending case", context do
      stats1 =
        Transactions.stats(
          context.user,
          context.from1,
          context.to1
        )

      stats2 =
        Transactions.stats(
          context.user,
          context.from2,
          context.to2
        )

      result = ComparedExpenses.call(stats1, "Month 1", stats2, "Month 2")

      assert result.sum_a == Decimal.new(255)
      assert result.sum_b == Decimal.new(120)

      assert result.numeric_diff == -135
      assert result.percentage_diff == -113
    end

    test "returns correct persentage diff and numeric diff for the more spending case", context do
      insert(:transaction,
        amount: "-200",
        transaction_category: context.pets_category,
        issued_at: context.issued_at2,
        user: context.user
      )

      stats1 =
        Transactions.stats(
          context.user,
          context.from1,
          context.to1
        )

      stats2 =
        Transactions.stats(
          context.user,
          context.from2,
          context.to2
        )

      result = ComparedExpenses.call(stats1, "Month 1", stats2, "Month 2")

      assert result.sum_a == Decimal.new(255)
      assert result.sum_b == Decimal.new(320)

      assert result.numeric_diff == 65
      assert result.percentage_diff == 25
    end
  end
end
