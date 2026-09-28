defmodule NervesLivebookFP3.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Livebook needs writable notebooks, but the rootfs is read-only:
    # copy any shipped notebook that isn't on /data yet (so notebooks
    # added by a firmware update show up), leaving attendee edits alone.
    sync_notebooks()

    # Scenic's supervisor, so notebooks can start viewports on the screen.
    children = [{Scenic, []}]

    with {:ok, pid} <-
           Supervisor.start_link(children,
             strategy: :one_for_one,
             name: NervesLivebookFP3.Supervisor
           ) do
      validate_firmware()
      {:ok, pid}
    end
  end

  # fwup installs a firmware as not validated; this release has started,
  # so mark its slot valid.
  defp validate_firmware do
    if Nerves.Runtime.mix_target() != :host do
      case Nerves.Runtime.validate_firmware() do
        :ok ->
          :ok

        {:error, reason} ->
          Logger.warning("[workshop] firmware validation failed: #{inspect(reason)}")
      end
    end
  end

  defp sync_notebooks do
    source =
      Application.get_env(:nerves_livebook_fp3, :notebooks_source, "/srv/livebook/notebooks")

    dest = Application.get_env(:nerves_livebook_fp3, :notebooks_dest, "/data/livebook/notebooks")

    if File.dir?(source) do
      File.mkdir_p!(dest)

      copied =
        for name <- File.ls!(source),
            dst_path = Path.join(dest, name),
            not File.exists?(dst_path) do
          File.copy!(Path.join(source, name), dst_path)
          name
        end

      if copied != [], do: Logger.info("[workshop] copied #{inspect(copied)} into #{dest}")
    else
      Logger.info("[workshop] no shipped notebooks at #{source}, skipping sync")
    end
  rescue
    e -> Logger.warning("[workshop] notebook sync failed: #{Exception.message(e)}")
  end
end
