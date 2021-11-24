defmodule MarkevichMoney.LoggerWithSentry do
  defmacro __using__(_) do
    quote do
      require Logger

      def log_exception(exception, stacktrace, extra \\ %{}) when is_map(extra) do
        Logger.error(Exception.format(:error, exception, stacktrace),
          crash_reason: {exception, stacktrace},
          extra: extra
        )

        Sentry.capture_exception(exception, stacktrace: stacktrace, extra: %{extra: extra})
      end

      def log_error_message(message, extra \\ %{}) when is_map(extra) do
        Logger.error(message, extra: extra)

        Sentry.capture_message(message, extra: %{extra: extra})
      end
    end
  end
end
