import Config

# Evaluated after all dependencies are compiled, so it's safe to call
# into :livebook here — unlike config.exs, which runs before deps.get.
config :livebook,
  default_runtime: Livebook.Runtime.Embedded.new(),
  default_app_runtime: Livebook.Runtime.Embedded.new(),
  runtime_modules: [Livebook.Runtime.Embedded]

# Livebook.config_runtime/0 sets these in standalone Livebook.
config :livebook,
  random_boot_id: :crypto.strong_rand_bytes(3),
  log_format: :text
