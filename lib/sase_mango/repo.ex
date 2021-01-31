defmodule SaseMango.Repo do
  use Ecto.Repo,
    otp_app: :sase_mango,
    adapter: Ecto.Adapters.Postgres
end
