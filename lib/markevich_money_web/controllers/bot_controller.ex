defmodule MarkevichMoneyWeb.BotController do
  use MarkevichMoneyWeb, :controller

  alias MarkevichMoney.Bots
  alias MarkevichMoney.Bots.Bot

  action_fallback MarkevichMoneyWeb.FallbackController

  # Nadia.set_webhook(url: "https://94ba2026.ngrok.io/api/bot/message")

  def compliment(conn, params) do
    messages = [
      "Варя красотка",
      "Варя милашка",
      "Варя самая лучшая жена",
      "Варя самая любимая",
      "Варя самая умная",
      "Варя самая обаятельная",
      "У вари лучшие булочки"
    ]

    message = Enum.at(messages, Enum.random(0..6))

    result = Nadia.send_message(-371_960_187, message)
    IO.inspect(result)
  end

  def answer_callback(callback_id) do
    Nadia.answer_callback_query(callback_id, text: "Узнаем что-нибудь новенькое о Варе?")
  end

  def message(conn, params) do
    IO.inspect(params)
    if params["callback_query"] do
      command = Jason.decode!(params["callback_query"]["data"])
      IO.inspect(command)
      if command["step"] == "compliment" do
        compliment(conn, params)
        answer_callback(params["callback_query"]["id"])
      end
    end
    if params["message"]["text"] == "/help" do
      message = """
        Я создан момогать Маркевичам следить за своим бюджетом

        /start - Начало работы
      """

      result = Nadia.send_message(-371_960_187, message)
    end

    if params["message"]["text"] == "/start" do
      callback_data =
        %{
          step: "compliment",
        }
        |> Jason.encode!()
      IO.puts(String.length(callback_data))

      markup = %Nadia.Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %Nadia.Model.InlineKeyboardButton{
              text: "Сделать комплимент Варе",
              callback_data: callback_data
            }
          ]
        ]
      }

      result = Nadia.send_message(-371_960_187, "Выберите дальнейшее действие", reply_markup: markup)
      IO.inspect(result)
    end

    json(conn, %{})
  end

  def index(conn, _params) do
    bots = Bots.list_bots()
    render(conn, "index.json", bots: bots)
  end

  def create(conn, %{"bot" => bot_params}) do
    with {:ok, %Bot{} = bot} <- Bots.create_bot(bot_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.bot_path(conn, :show, bot))
      |> render("show.json", bot: bot)
    end
  end

  def show(conn, %{"id" => id}) do
    bot = Bots.get_bot!(id)
    render(conn, "show.json", bot: bot)
  end

  def update(conn, %{"id" => id, "bot" => bot_params}) do
    bot = Bots.get_bot!(id)

    with {:ok, %Bot{} = bot} <- Bots.update_bot(bot, bot_params) do
      render(conn, "show.json", bot: bot)
    end
  end

  def delete(conn, %{"id" => id}) do
    bot = Bots.get_bot!(id)

    with {:ok, %Bot{}} <- Bots.delete_bot(bot) do
      send_resp(conn, :no_content, "")
    end
  end
end
