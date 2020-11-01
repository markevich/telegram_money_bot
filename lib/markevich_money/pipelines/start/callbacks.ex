defmodule MarkevichMoney.Pipelines.Start.Callbacks do
  use MarkevichMoney.Constants
  alias MarkevichMoney.CallbackData
  alias MarkevichMoney.Users
  alias MarkevichMoney.Steps.Telegram.{AnswerCallback, SendMessage, SendPhoto}

  def call(%CallbackData{callback_data: %{"pipeline" => @start_callback}} = callback_data) do
    callback_data
    |> AnswerCallback.call()

    user = upsert_user(callback_data)
    personal_email = "#{user.notification_email}@gmail.com"

    send_personal_email(callback_data, personal_email)
    send_instructions(callback_data, personal_email)
  end

  defp send_personal_email(callback_data, personal_email) do
    message1 = """
    Приступим!

    Для работы с ботом тебе присвоен персональный  E-mail -
    """

    message2 = "```#{personal_email}```"

    message3 = """
    Он понадобится для настройки и корректного функционирования бота.

    Пожалуйста, последовательно выполни все шаги, описанные ниже:
    """

    callback_data
    |> Map.put(:output_message, message1)
    |> SendMessage.call()
    |> Map.put(:output_message, message2)
    |> SendMessage.call()
    |> Map.put(:output_message, message3)
    |> SendMessage.call()
  end

  defp send_instructions(callback_data, personal_email) do
    send_instruction1(callback_data)
    send_instruction2(callback_data)
    send_instruction3(callback_data)
    send_instruction4(callback_data)
    send_instruction5(callback_data)
    send_instruction6(callback_data, personal_email)
    send_instruction7(callback_data)
  end

  defp send_instruction1(callback_data) do
    message = """
    Перейди на страницу https://click.alfa-bank.by/ и войди в личный кабинет. Если у тебя ещё нет аккаунта в "Альфа-Клике" - зарегистрируйся.
    """

    callback_data
    |> Map.put(:output_file_id, get_file_id(:alfa_click_email1))
    |> Map.put(:output_message, message)
    |> SendPhoto.call()
  end

  defp send_instruction2(callback_data) do
    message = """
    Наведи курсор на пункт меню "Мои карты" и нажми "Альфа-Чек".
    """

    callback_data
    |> Map.put(:output_file_id, get_file_id(:alfa_click_email2))
    |> Map.put(:output_message, message)
    |> SendPhoto.call()
  end

  defp send_instruction3(callback_data) do
    message = """
    Выбери карту, к которой хочешь подключить бота. Нажми ссылку "Подключить" напротив "Email-оповещение".
    """

    callback_data
    |> Map.put(:output_file_id, get_file_id(:alfa_click_email3))
    |> Map.put(:output_message, message)
    |> SendPhoto.call()
  end

  defp send_instruction4(callback_data) do
    message = """
    Введи выданный тебе ранее персональный E-mail. Прими условия "Альфа-Чека" и нажми кнопку "Далее".
    """

    callback_data
    |> Map.put(:output_file_id, get_file_id(:alfa_click_email4))
    |> Map.put(:output_message, message)
    |> SendPhoto.call()
  end

  defp send_instruction5(callback_data) do
    message = """
    Подтверди своё действие при помощи SMS-пароля.
    """

    callback_data
    |> Map.put(:output_file_id, get_file_id(:alfa_click_email5))
    |> Map.put(:output_message, message)
    |> SendPhoto.call()
  end

  defp send_instruction6(callback_data, personal_email) do
    message = """
    Перепроверь правильность введенного адреса. Твой персональный E-mail выглядит следующим образом: #{
      personal_email
    }
    """

    callback_data
    |> Map.put(:output_file_id, get_file_id(:alfa_click_email6))
    |> Map.put(:output_message, message)
    |> SendPhoto.call()
  end

  defp send_instruction7(callback_data) do
    message = """
    Настройка завершена! Поздравляю!

    Ты получишь оповещение о своей первой трате, как только совершишь покупку, используя подключенную к аккаунту "Альфа-Клик" банковскую карту.
    """

    callback_data
    |> Map.put(:output_message, message)
    |> SendMessage.call()
  end

  defp upsert_user(callback_data) do
    %{
      name: username(callback_data.from),
      telegram_chat_id: callback_data.chat_id
    }
    |> Users.upsert_user!()
  end

  # TODO: Move that to telegram context
  defp username(from) do
    if Map.has_key?(from, "username") do
      from["username"]
    else
      from["first_name"]
    end
  end

  defp get_file_id(picture_name) do
    Application.get_env(:markevich_money, :tg_file_ids)[:user_registration][picture_name]
  end
end
