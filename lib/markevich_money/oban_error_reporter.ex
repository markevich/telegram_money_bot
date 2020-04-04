defmodule ObanErrorReporter do
  require Logger

  def handle_event([:oban, :failure], measure, meta, _) do
    context =
      meta
      |> Map.take([:id, :args, :queue, :worker])
      |> Map.merge(measure)

    Sentry.capture_exception(meta.error, stacktrace: meta.stack, extra: context)
    Logger.error(Exception.format(:error, meta.error, meta.stack))
  end

  def handle_event([:oban, :trip_circuit], _measure, meta, _) do
    context = Map.take(meta, [:name])

    Sentry.capture_exception(meta.error, stacktrace: meta.stack, extra: context)
    Logger.error(Exception.format(:error, meta.error, meta.stack))
  end
end
