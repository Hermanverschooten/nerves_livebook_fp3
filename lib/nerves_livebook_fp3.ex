defmodule NervesLivebookFP3 do
  @moduledoc """
  Workshop firmware for the Fairphone 3 / 3+, built on Nerves.

  Boots into a Livebook served on port 4000. The notebooks ship in
  `priv/samples`, are copied to `/data/livebook/notebooks` (writable) at
  boot and starred so they appear on Livebook's home page.

  Models are not in the firmware image: `nerves_ai` downloads them to
  `/data/models` at boot, or you copy them there over SSH. See the README.
  """
end
