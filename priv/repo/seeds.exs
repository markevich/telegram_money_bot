# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MarkevichMoney.Repo.insert!(%MarkevichMoney.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

categories_with_same_folders = [
  "🏔️ Туризм",
  "👕 Одежда",
  "💈 Красота",
  "🏅 Спорт",
  "🧾 Налоги",
  "🎨 Хобби",
  "👪 Семья",
  "🏷️ Другое",
  "🎁 Праздники",
  "🔋 Техника",
  "💖 Здоровье",
  "📚 Образование",
  "🐈 Питомцы",
  "🤍 Солидарность",
  "🏦 Кредит",
  "🔄 Подписки"
]

Enum.each(categories_with_same_folders, fn category_name ->
  folder =
    MarkevichMoney.Repo.insert!(%MarkevichMoney.Transactions.TransactionCategoryFolder{
      name: category_name,
      has_single_category: true
    })

  MarkevichMoney.Repo.insert!(%MarkevichMoney.Transactions.TransactionCategory{
    name: category_name,
    transaction_category_folder: folder
  })
end)

food_folder_name = "🍔 Еда"
entertainment_folder_name = "🎉 Развлечения"
transport_folder_name = "🚜 Транспорт"
home_folder_name = "🏠 Дом"
kids_folder_name = "🧒 Дети"

food_folder =
  MarkevichMoney.Repo.insert!(%MarkevichMoney.Transactions.TransactionCategoryFolder{
    name: food_folder_name,
    has_single_category: false
  })

entertainment_folder =
  MarkevichMoney.Repo.insert!(%MarkevichMoney.Transactions.TransactionCategoryFolder{
    name: entertainment_folder_name,
    has_single_category: false
  })

transport_folder =
  MarkevichMoney.Repo.insert!(%MarkevichMoney.Transactions.TransactionCategoryFolder{
    name: transport_folder_name,
    has_single_category: false
  })

home_folder =
  MarkevichMoney.Repo.insert!(%MarkevichMoney.Transactions.TransactionCategoryFolder{
    name: home_folder_name,
    has_single_category: false
  })

kids_folder =
  MarkevichMoney.Repo.insert!(%MarkevichMoney.Transactions.TransactionCategoryFolder{
    name: kids_folder_name,
    has_single_category: false
  })

[
  "🍽 Кафе",
  "🛒 Продукты"
]
|> Enum.each(fn category_name ->
  MarkevichMoney.Repo.insert!(%MarkevichMoney.Transactions.TransactionCategory{
    name: category_name,
    transaction_category_folder: food_folder
  })
end)

[
  "🌐 Онлайн",
  "🎲 Оффлайн"
]
|> Enum.each(fn category_name ->
  MarkevichMoney.Repo.insert!(%MarkevichMoney.Transactions.TransactionCategory{
    name: category_name,
    transaction_category_folder: entertainment_folder
  })
end)

[
  "🏎️ Личный",
  "🚖 Такси",
  "🚃 Общественный",
  "🚴 Шеринг"
]
|> Enum.each(fn category_name ->
  MarkevichMoney.Repo.insert!(%MarkevichMoney.Transactions.TransactionCategory{
    name: category_name,
    transaction_category_folder: transport_folder
  })
end)

[
  "🧾 Платежи",
  "🛋️ Мебель",
  "💡 Обслуживание",
  "🛠️️ Ремонт"
]
|> Enum.each(fn category_name ->
  MarkevichMoney.Repo.insert!(%MarkevichMoney.Transactions.TransactionCategory{
    name: category_name,
    transaction_category_folder: home_folder
  })
end)

[
  "🧒👕 Одежда",
  "🧒📚 Обучение",
  "🧒🎉 Развлечения",
  "🧒💖 Здоровье"
]
|> Enum.each(fn category_name ->
  MarkevichMoney.Repo.insert!(%MarkevichMoney.Transactions.TransactionCategory{
    name: category_name,
    transaction_category_folder: kids_folder
  })
end)
