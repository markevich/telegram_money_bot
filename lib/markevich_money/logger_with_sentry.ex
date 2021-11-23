defmodule MarkevichMoney.LoggerWithSentry do
  defmacro __using__(_) do
    quote do
      require Logger

      def log_exception(exception, stacktrace, extra \\ %{}) when is_map(extra) do
        Logger.error(Exception.format(:error, exception, stacktrace),
          crash_reason: {exception, stacktrace},
          extra: extra
        )
      end

      def log_error_message(message, metadata \\ %{}) do
        Logger.error(message, extra: metadata)
      end
    end
  end
end
