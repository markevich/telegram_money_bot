defmodule MarkevichMoney.LoggerWithSentry do
  defmacro __using__(_) do
    quote do
      require Logger

      def log_exception(exception, stacktrace, extra \\ %{}) do
        Logger.error(Exception.format(:error, exception, stacktrace),
          crash_reason: {exception, stacktrace},
          extra: extra
        )
      end

      def log_error_message(message, metadata) do
        message_with_meta =
          metadata
          |> Enum.reduce(
            message,
            fn {key, value}, acc ->
              "#{acc}\n#{key}: #{inspect(value)}"
            end
          )

        Logger.error(message_with_meta, extra: metadata)
      end
    end
  end
end
