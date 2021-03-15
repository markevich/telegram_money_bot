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

categories = [
  "🍔 Еда",
  "🚗 Транспорт",
  "🏔️ Туризм",
  "👕 Одежда",
  "💈 Красота",
  "🎉 Развлечения",
  "🏅 Спорт",
  "🧾 Налоги",
  "🏠 Дом",
  "🎨 Хобби",
  "👪 Семья",
  "🏷️ Другое",
  "🎄 Праздники",
  "🔋 Техника",
  "💖 Здоровье",
  "📚 Образование",
  "🐈 Питомцы",
  "🤍 Солидарность",
  "🏦 Кредит"
]

Enum.each(categories, fn category_name ->
  MarkevichMoney.Repo.insert!(%MarkevichMoney.Transactions.TransactionCategory{
    name: category_name
  })
end)
