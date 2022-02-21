defmodule MarkevichMoney.Priorbank.IntegrationTest do
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.Constants
  use MecksUnit.Case

  alias MarkevichMoney.Priorbank
  alias MarkevichMoney.Priorbank.Integration

  # defp setup_full_connection(context) do
  # Map.put(context, :connection, insert(:connection))
  # %{
  # connection: insert(:connection)
  # }
  # end

  defmock MarkevichMoney.Priorbank.Api, preserve: true do
    def authenticated?(_) do
      raise "That shouldn't be called in tests. Please mock the request."
    end

    def get_cards_details(_) do
      raise "That shouldn't be called in tests. Please mock the request."
    end

    def authenticate(_, _) do
      raise "That shouldn't be called in tests. Please mock the request."
    end
  end

  # describe "fetch_priorbank_transactions when authenticated" do
  def create_connection(context) do
    context
    |> Map.put(:connection, insert(:priorbank_connection))
  end

  describe "fetch_priorbank_transactions when authenticated" do
    setup [:create_connection]

    defmock MarkevichMoney.Priorbank.Api do
      def authenticated?(_) do
        true
      end

      def get_cards_details(_) do
        %{}
      end
    end

    mocked_test "does not update the connection session", context do
      original_connection = context.connection

      Integration.fetch_priorbank_transactions(context.connection)
      maybe_updated_connection = Priorbank.get_connection!(context.connection.id)

      assert original_connection == maybe_updated_connection
    end
  end

  describe "fetch_priorbank_transactions when not authenticated" do
    setup [:create_connection]

    defmock MarkevichMoney.Priorbank.Api do
      def authenticated?(_) do
        false
      end

      def get_cards_details(_) do
        %{}
      end

      def authenticate(_, _) do
        {:ok,
         %{
           client_secret: "i am client secret",
           access_token: "i am access token",
           user_session: "i am user session"
         }}
      end
    end

    mocked_test "updates the connection session", context do
      original_connection = context.connection

      Integration.fetch_priorbank_transactions(context.connection)
      updated_connection = Priorbank.get_connection!(context.connection.id)

      assert original_connection != updated_connection

      assert updated_connection.client_secret == "i am client secret"
      assert updated_connection.access_token == "i am access token"
      assert updated_connection.user_session == "i am user session"
    end
  end

  describe "convert_to_readable_transaction_attributes" do
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
                  "abortedCard" => "8500",
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
                    "transCardNum" => "8500",
                    "transactionList" => regular_transactions,
                    "turnOverCard" => -42.65
                  }
                ]
              },
              "addrLineA" => " Вася пупкин",
              "addrLineB" => "",
              "addrLineC" => "220000 Минск",
              "amountAvailable" => 848.11,
              "cardType" => "MASTERCARD",
              "contractCurrIso" => "BYN",
              "contractNumber" => "1991",
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
            "id" => 61_576_321,
            "identifier" => "1530",
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
              "addrLineA" => " Вася пупкин",
              "addrLineB" => "",
              "addrLineC" => "220000 Минск",
              "amountAvailable" => 199.61,
              "cardType" => "VISA VIRTUAL",
              "contractCurrIso" => "USD",
              "contractNumber" => "5098",
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

    mocked_test "converts api response to readable transactions metadata", context do
      converted_attributes =
        Integration.convert_to_readable_transaction_attributes(context.api_response_mock)

      assert(
        converted_attributes == [
          %{
            account: "BYN cards",
            amount: 1.0,
            balance: "0",
            currency_code: "BYN",
            issued_at: ~N[2021-04-16 13:42:36],
            to: "BLR MINSK P2P SDBO NO FEE",
            status: @transaction_status_bank_fund_freeze
          },
          %{
            account: "BYN cards",
            amount: -522.0,
            balance: "0",
            currency_code: "BYN",
            external_amount: -200.0,
            external_currency: "USD",
            issued_at: ~N[2021-04-16 13:38:03],
            to: "BLR MINSK P2P SDBO NO FEE",
            status: @transaction_status_bank_fund_freeze
          },
          %{
            account: "BYN cards",
            amount: -21.0,
            balance: "0",
            currency_code: "BYN",
            issued_at: ~N[2021-04-15 17:19:53],
            to: "BLR MINSK IR WWW.NEW.BYCARD.BY B",
            status: @transaction_status_bank_fund_freeze
          },
          %{
            account: "BYN cards",
            amount: -3.3,
            balance: "0",
            currency_code: "BYN",
            issued_at: ~N[2021-04-14 12:07:57],
            to: "NLD Amsterdam Yandex.Taxi",
            status: @transaction_status_normal
          },
          %{
            account: "BYN cards",
            amount: -5.15,
            balance: "0",
            currency_code: "BYN",
            external_amount: -1.95,
            external_currency: "USD",
            issued_at: ~N[2021-04-14 17:02:00],
            to: "LUX 19, RUE DE BI ALIEXPRESS",
            status: @transaction_status_normal
          }
        ]
      )
    end
  end

  describe "update_last_fetched_at!" do
    setup do
      %{
        connection: insert(:priorbank_connection, last_fetched_at: ~U[2021-05-02 17:19:08Z])
      }
    end

    mocked_test "Updates the connection last_fetched_at", context do
      updated_connection = Integration.update_last_fetched_at!(context.connection)

      assert updated_connection.last_fetched_at
      refute updated_connection.last_fetched_at == context.connection.last_fetched_at
    end
  end
end
