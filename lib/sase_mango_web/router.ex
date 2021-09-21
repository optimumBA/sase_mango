defmodule SaseMangoWeb.Router do
  use SaseMangoWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SaseMangoWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SaseMangoWeb do
    pipe_through :browser

    live "/", SecuritiesLive, :index
    live "/calculator", CalculatorLive, :index
    live_dashboard "/dashboard", metrics: SaseMangoWeb.Telemetry
  end

  # Other scopes may use custom stacks.
  # scope "/api", SaseMangoWeb do
  #   pipe_through :api
  # end
end
