# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :sase_mango,
  ecto_repos: [SaseMango.Repo]

# Configures the endpoint
config :sase_mango, SaseMangoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "jCgCDyZuSaXc4fFMhmNxNeqxPWK/4MZKg4Z5ZmSJUu2GXBRjhNxSxaFcYUL+OtQ8",
  render_errors: [view: SaseMangoWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: SaseMango.PubSub,
  live_view: [signing_salt: "9Js17LYE"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :sase_mango, SaseMango.Scheduler,
  jobs: [
    # Every weekday at 3 PM
    {"0 15 * * 1-5", {SaseMango.SecuritiesUpdater, :update, []}},
    # Every 5 minutes while markets are open (Mon-Fri 10:00-13:30)
    {"*/5 10-12 * * 1-5", {SaseMango.TickerUpdater, :update, []}},
    {"0-30/5 13 * * 1-5", {SaseMango.TickerUpdater, :update, []}},
    # Warm the securities cache on boot
    {"@reboot", {SaseMango.SecuritiesCache, :update, []}}
  ],
  timezone: "Europe/Sarajevo"

config :wallaby, max_wait_time: 10_000

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
