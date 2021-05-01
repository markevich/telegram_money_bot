defmodule MarkevichMoney.PriorbankTest do
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.MockNadia, async: true

  alias MarkevichMoney.Priorbank

  describe "happy path" do
    setup do
      blocked_transactions = [
        # трата
        %{
          "amount" => 21.0,
          "hce" => false,
          "transAmount" => 21.0,
          "transCurrIso" => "BYN",
          "transDate" => "2021-04-15T00:00:00+03:00",
          "transDateSpecified" => true,
          "transDetails" => "Retail BLR MINSK IR WWW.NEW.BYCARD.BY B",
          "transTime" => "17:19:53"
        },
        # трата в другой валюте
        %{
          "amount" => 522.0,
          "hce" => false,
          "transAmount" => 200.0,
          "transCurrIso" => "USD",
          "transDate" => "2021-04-16T00:00:00+03:00",
          "transDateSpecified" => true,
          "transDetails" => "CH Debit BLR MINSK P2P SDBO NO FEE",
          "transTime" => "13:38:03"
        },
        # Поступление
        %{
          "amount" => -1.0,
          "hce" => false,
          "transAmount" => 1.0,
          "transCurrIso" => "BYN",
          "transDate" => "2021-04-16T00:00:00+03:00",
          "transDateSpecified" => true,
          "transDetails" => "CH Payment BLR MINSK P2P SDBO NO FEE",
          "transTime" => "13:42:36"
        }
      ]

      regular_transactions = [
        # другая валюта
        %{
          "accountAmount" => -5.15,
          "amount" => -1.95,
          "feeAmount" => 0.0,
          "hce" => false,
          "postingDate" => "2021-04-16T00:00:00+03:00",
          "postingDateSpecified" => true,
          "transCurrIso" => "USD",
          "transDate" => "2021-04-14T00:00:00+03:00",
          "transDateSpecified" => true,
          "transDetails" => "Retail LUX 19, RUE DE BI ALIEXPRESS",
          "transTime" => "17:02:00"
        },
        # обычная трата
        %{
          "accountAmount" => -3.3,
          "amount" => -3.3,
          "feeAmount" => 0.0,
          "hce" => false,
          "postingDate" => "2021-04-15T00:00:00+03:00",
          "postingDateSpecified" => true,
          "transCurrIso" => "BYN",
          "transDate" => "2021-04-14T00:00:00+03:00",
          "transDateSpecified" => true,
          "transDetails" => "Retail NLD Amsterdam Yandex.Taxi",
          "transTime" => "12:07:57"
        }
      ]

      api_response_mock = %{
        "errorMessage" => "",
        "externalErrorCode" => "",
        "internalErrorCode" => 0,
        "result" => [
          %{
            "contract" => %{
              "abortedContractList" => [
                %{
                  "abortedCard" => "8530",
                  "abortedTransactionList" => blocked_transactions
                }
              ],
              "account" => %{
                "beginBalance" => 1464.81,
                "endBalance" => 1422.16,
                "feeContracr" => 0.0,
                "minusContracr" => 42.65,
                "plusContracr" => 0.0,
                "transCardList" => [
                  %{
                    "feeCard" => 0.0,
                    "minusCard" => 42.65,
                    "plusCard" => 0.0,
                    "transCardNum" => "8530",
                    "transactionList" => regular_transactions,
                    "turnOverCard" => -42.65
                  }
                ]
              },
              "addrLineA" => " Дарья Ранда",
              "addrLineB" => "",
              "addrLineC" =>
                "220000 Минск д.22 кв.15 улица Коммунистическая город Минск Минская область",
              "amountAvailable" => 848.11,
              "cardType" => "MASTERCARD",
              "contractCurrIso" => "BYN",
              "contractNumber" => "6391",
              "creditLimit" => 0.0,
              "message" => %{"messageDateSpecified" => false, "messageString" => ""},
              "prodNum" => 0,
              "prodType" => "D",
              "totalBlocked" => 574.05
            },
            "currentDebit" => %{
              "due" => 0.0,
              "interest" => 0.0,
              "monthlyFee" => 0.0,
              "ovdField" => 0.0,
              "total" => 0.0
            },
            "id" => 68_576_321,
            "identifier" => "8530",
            "monthDebit" => %{
              "due" => 0.0,
              "dueDateSpecified" => false,
              "interest" => 0.0,
              "monthlyFee" => 0.0,
              "ovd" => 0.0,
              "total" => 0.0
            }
          },
          %{
            "contract" => %{
              "abortedContractList" => [
                %{
                  "abortedCard" => "4737",
                  "abortedTransactionList" => []
                }
              ],
              "account" => %{
                "beginBalance" => 0.0,
                "endBalance" => 0.0,
                "feeContracr" => 0.0,
                "minusContracr" => 0.0,
                "plusContracr" => 0.0,
                "transCardList" => []
              },
              "addrLineA" => " Дарья Ранда",
              "addrLineB" => "",
              "addrLineC" =>
                "220000 Минск д.22 кв.15 улица Коммунистическая город Минск Минская область",
              "amountAvailable" => 199.61,
              "cardType" => "VISA VIRTUAL",
              "contractCurrIso" => "USD",
              "contractNumber" => "5498",
              "creditLimit" => 0.0,
              "message" => %{"messageDateSpecified" => false, "messageString" => ""},
              "prodNum" => 0,
              "prodType" => "D",
              "totalBlocked" => -199.61
            },
            "currentDebit" => %{
              "due" => 0.0,
              "interest" => 0.0,
              "monthlyFee" => 0.0,
              "ovdField" => 0.0,
              "total" => 0.0
            },
            "id" => 69_013_118,
            "identifier" => "4737",
            "monthDebit" => %{
              "due" => 0.0,
              "dueDateSpecified" => false,
              "interest" => 0.0,
              "monthlyFee" => 0.0,
              "ovd" => 0.0,
              "total" => 0.0
            }
          }
        ],
        "success" => true,
        "token" => false,
        "tokenFields" => nil
      }

      %{
        api_response_mock: api_response_mock,
        blocked_transactions: blocked_transactions,
        regular_transactions: regular_transactions
      }
    end

    test ".select_byn_accounts", context do
      selected_accounts = Priorbank.select_byn_accounts(context.api_response_mock)

      [account] = selected_accounts

      assert(get_in(account, ["contract", "contractCurrIso"]) == "BYN")
    end

    test ".select_blocked_transactions", context do
      [account] = Priorbank.select_byn_accounts(context.api_response_mock)
      assert(Priorbank.select_blocked_transactions(account) == context.blocked_transactions)
    end

    test ".select_regular_transactions", context do
      [account] = Priorbank.select_byn_accounts(context.api_response_mock)
      assert(Priorbank.select_regular_transactions(account) == context.regular_transactions)
    end

    test ".extract_transactions_attributes", context do
      extracted = Priorbank.extract_transactions_attributes(context.api_response_mock)

      assert extracted == [
               %{
                 account: "BYN cards",
                 amount: 1.0,
                 balance: "0",
                 currency_code: "BYN",
                 issued_at: ~N[2021-04-16 13:42:36],
                 to: "BLR MINSK P2P SDBO NO FEE"
               },
               %{
                 account: "BYN cards",
                 amount: -522.0,
                 balance: "0",
                 currency_code: "BYN",
                 external_amount: -200.0,
                 external_currency: "USD",
                 issued_at: ~N[2021-04-16 13:38:03],
                 to: "BLR MINSK P2P SDBO NO FEE"
               },
               %{
                 account: "BYN cards",
                 amount: -21.0,
                 balance: "0",
                 currency_code: "BYN",
                 issued_at: ~N[2021-04-15 17:19:53],
                 to: "BLR MINSK IR WWW.NEW.BYCARD.BY B"
               },
               %{
                 account: "BYN cards",
                 amount: -3.3,
                 balance: "0",
                 currency_code: "BYN",
                 issued_at: ~N[2021-04-14 12:07:57],
                 to: "NLD Amsterdam Yandex.Taxi"
               },
               %{
                 account: "BYN cards",
                 amount: -5.15,
                 balance: "0",
                 currency_code: "BYN",
                 external_amount: -1.95,
                 external_currency: "USD",
                 issued_at: ~N[2021-04-14 17:02:00],
                 to: "LUX 19, RUE DE BI ALIEXPRESS"
               }
             ]
    end

    mocked_test ".add_new_transactions", context do
      user = insert(:user)
      inserted = Priorbank.add_new_transactions(context.api_response_mock, user)
    end
  end
end
