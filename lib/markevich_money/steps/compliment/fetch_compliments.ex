defmodule MarkevichMoney.Steps.Compliment.FetchCompliments do
  def call(payload) do
    Map.put(payload, :compliments, [
      "Варя красотка",
      "Варя милашка",
      "Варя самая лучшая жена",
      "Варя самая любимая",
      "Варя самая умная",
      "Варя самая обаятельная",
      "У вари лучшие булочки",
      "Варя гений",
      "Варя сверхразум"
    ])
  end
end
