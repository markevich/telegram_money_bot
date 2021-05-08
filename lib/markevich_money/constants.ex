defmodule MarkevichMoney.Constants do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      # callbacks
      @choose_category_callback "choose_category"
      @choose_category_short_mode "ccsm"
      @choose_category_full_mode "ccfm"
      @set_category_callback "set_category"

      @stats_callback "stats"
      @stats_callback_current_week "c_week"
      @stats_callback_current_month "c_month"
      @stats_callback_previous_month "p_month"
      @stats_callback_lifetime "all"

      @delete_transaction_callback "dlt_trn"
      @delete_transaction_callback_prompt "ask"
      @delete_transaction_callback_confirm "dlt"
      @delete_transaction_callback_cancel "cnl"

      @limits_stats_callback "limits_stats"

      @start_callback "start"

      @help_callback "help"
      @help_callback_newby "newby"
      @help_callback_add "add"
      @help_callback_stats "stats"
      @help_callback_limits "limits"
      @help_callback_support "support"
      @help_callback_bug "bug"
      @help_callback_edit_description "edit_description"

      # messages
      @help_message "/help"
      @stats_message "/stats"
      @add_message "/add"
      @limits_message "/limits"
      @limit_message "/limit"
      @start_message "/start"

      # events
      @transaction_created_event "transaction_created"
      @transaction_updated_event "transaction_updated"

      @transaction_type_income "income"
      @transaction_type_expense "expense"
      @transaction_type_unknown "unknown"

      @manual_account "Добавленные вручную"
    end
  end
end
