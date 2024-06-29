defmodule SaseMango.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # Start the Telemetry supervisor
        SaseMangoWeb.Telemetry,
        # Start the Ecto repository
        SaseMango.Repo,
        # Start the PubSub system
        {Phoenix.PubSub, name: SaseMango.PubSub},
        # Start the Endpoint (http/https)
        SaseMangoWeb.Endpoint,
        # Start a worker by calling: SaseMango.Worker.start_link(arg)
        # {SaseMango.Worker, arg}
        SaseMango.SaseMangoClient.child_spec()
      ] ++ more_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SaseMango.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp more_children(env \\ Application.get_env(:sase_mango, :env))
  defp more_children(:test), do: []

  defp more_children(_env) do
    [
      SaseMango.SecuritiesCache,
      SaseMango.BargainsCache,
      SaseMango.Scheduler
    ]
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SaseMangoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
