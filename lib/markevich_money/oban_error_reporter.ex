defmodule ObanErrorReporter do
  require Logger

  def handle_event([:oban, :job, :exception], measure, meta, _) do
    context =
      meta
      |> Map.take([:id, :args, :queue, :worker])
      |> Map.merge(measure)

    Logger.error(Exception.format(:error, meta.error, meta.stacktrace), extra: context)
  end

  def handle_event([:oban, :circuit, :trip], _measure, meta, _) do
    Logger.error(Exception.format(:error, meta.error, meta.stacktrace), extra: meta)
  end
end
