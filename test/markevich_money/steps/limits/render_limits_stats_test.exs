defmodule MarkevichMoney.Steps.Limits.RenderLimitsStatsTest do
  use MarkevichMoney.DataCase, async: true
  use MarkevichMoney.Constants

  alias MarkevichMoney.Gamifications
  alias MarkevichMoney.Steps.Limits.RenderLimitsStats, as: Render

  # TODO: Copy/replace test for non empty limits from limits callbacks test
  describe ".call with empty limits" do
    setup do
      user = insert(:user)
      limits = Gamifications.list_categories_limits(user)

      %{
        user: user,
        limits: limits
      }
    end

    test "Renders empty limits message", context do
      reply_payload = Render.call(%{limits: context.limits, current_user: context.user})
      assert(Map.has_key?(reply_payload, :output_message))

      assert(
        reply_payload[:output_message] == """
        ```
        Отсутствуют установленные лимиты
        ```
        """
      )
    end
  end
end
