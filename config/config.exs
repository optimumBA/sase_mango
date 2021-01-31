import Config

config :postgrex, :json_library, Jason

config :sase_mango, SaseMango.Repo,
  database: "sase_mango",
  hostname: "localhost"

config :sase_mango, ecto_repos: [SaseMango.Repo]
