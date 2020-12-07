# This file is responsible for storing all file ids in telegram

use Mix.Config

config :markevich_money, :tg_file_ids,
  user_registration: %{
    alfa_click_email1:
      "AgACAgIAAxkBAAInBl_N_7KkBHJlGty_P-nE3YnSXhWoAAIBrzEbFEpwSimrjG6UhWQzQRjnly4AAwEAAwIAA3kAA4sYBAABHgQ",
    alfa_click_email2:
      "AgACAgIAAxkBAAInB1_N_8pH6jF3Of-AQGblP_qgMRSGAAIDrzEbFEpwSi4cBluQRR1IBxeili4AAwEAAwIAA3kAA93sBAABHgQ",
    alfa_click_email3:
      "AgACAgIAAxkBAAInCF_OAAFDRD5NDnDh8Gwvughpy-r77QACBK8xGxRKcEqnrvoE84sbvn_rF5guAAMBAAMCAAN5AAPZEQQAAR4E",
    alfa_click_email4:
      "AgACAgIAAxkBAAInCV_OAAFaiAjrElnWBRw62SOZFHRxtwACBa8xGxRKcEprIzbxCcdr_MltU5guAAMBAAMCAAN5AANE_AMAAR4E",
    alfa_click_email5:
      "AgACAgIAAxkBAAInCl_OAAFyHYqnzbOpBMa9A4JJKPc1fAACBq8xGxRKcEqb98017g5hq8RP85cuAAMBAAMCAAN5AAO5-QMAAR4E",
    alfa_click_email6:
      "AgACAgIAAxkBAAInC1_OAAGH0_wewjzrgM4pv6hw60I3AwACB68xGxRKcEqQ-SSbjldHIyWf6JcuAAMBAAMCAAN5AAO4DAQAAR4E"
  },
  help: %{
    newby: %{
      transaction_example:
        "AgACAgIAAxkBAAInDV_OAAHeA4LMB6iOZ3e4GxMufv5jOgACCK8xGxRKcEo0Vy-knxjFc76odJcuAAMBAAMCAAN4AAOvHQQAAR4E"
    }
  },
  releases: %{
    "1.0" =>
      "AgACAgIAAxkBAAIHo1-2pJgcWxySZMbU_aoW3OBl_RHLAALKrzEb1eawSQQMymAAAZQUi4KpdJcuAAMBAAMCAAN4AAPYVAMAAR4E"
  }
