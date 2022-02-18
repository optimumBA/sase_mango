# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :sase_mango,
  ecto_repos: [SaseMango.Repo],
  env: config_env()

# Configures the endpoint
config :sase_mango, SaseMangoWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: SaseMangoWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: SaseMango.PubSub,
  live_view: [signing_salt: "9Js17LYE"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

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

config :tailwind,
  version: "3.0.23",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
