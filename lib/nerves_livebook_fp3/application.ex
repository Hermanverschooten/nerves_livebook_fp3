defmodule NervesLivebookFP3.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Livebook needs writable notebooks, but the release is read-only:
    # copy any shipped notebook that isn't on /data yet (so notebooks
    # added by a firmware update show up), leaving attendee edits alone.
    # Starring them lists them on Livebook's home page.
    sync_notebooks()
    star_notebooks()

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

  defp notebooks_dest do
    Application.get_env(:nerves_livebook_fp3, :notebooks_dest, "/data/livebook/notebooks")
  end

  defp sync_notebooks do
    source = Application.app_dir(:nerves_livebook_fp3, "priv/samples")
    dest = notebooks_dest()

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

  # Starred notebooks show newest first and re-starring is a no-op, so
  # star in reverse order to list 00 first.
  defp star_notebooks do
    dest = notebooks_dest()

    if Process.whereis(Livebook.NotebookManager) && File.dir?(dest) do
      for name <-
            dest
            |> File.ls!()
            |> Enum.filter(&String.ends_with?(&1, ".livemd"))
            |> Enum.sort(:desc) do
        path = Path.join(dest, name)
        file = Livebook.FileSystem.File.local(path)
        Livebook.NotebookManager.add_starred_notebook(file, notebook_title(path, name))
      end
    end
  rescue
    e -> Logger.warning("[workshop] starring notebooks failed: #{Exception.message(e)}")
  end

  defp notebook_title(path, fallback) do
    path
    |> File.stream!()
    |> Enum.find_value(fallback, fn
      "# " <> title -> String.trim(title)
      _ -> nil
    end)
  end
end
