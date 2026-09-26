defmodule NervesLivebookFP3.Assets do
  @moduledoc false
  # Scenic's static assets: the Roboto fonts bundled with Scenic.
  use Scenic.Assets.Static,
    otp_app: :nerves_livebook_fp3,
    sources: [{:scenic, "deps/scenic/assets"}]
end
