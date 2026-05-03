import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :grid_ex, GridExWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "AJ7Z9oY/3sPrz8FKmwFF840O9UeOznpv6eP6/KYs2EgIdywqCgOyEKBk5Vem46cG",
  server: false

# In test we don't send emails
config :grid_ex, GridEx.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
