defmodule SaseMangoWeb.Router do
  use SaseMangoWeb, :router

  @dialyzer {:nowarn_function, admin_auth: 2}

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SaseMangoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug :admin_auth, env: Application.compile_env(:sase_mango, :env)
  end

  import Phoenix.LiveDashboard.Router

  scope "/", SaseMangoWeb do
    pipe_through [:browser, :admin]

    live_dashboard "/dashboard", ecto_repos: [SaseMango.Repo], metrics: SaseMangoWeb.Telemetry

    live_session :default do
      live "/", SecuritiesLive.Index, :securities
      live "/bargains", SecuritiesLive.Index, :bargains
      live "/calculator", CalculatorLive.Index, :index
      live "/investors", InvestorsListLive.Index, :index
      live "/investors/:slug", InvestorsListLive.Show, :index
      live "/issuer/:symbol", SecuritiesLive.Show, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", SaseMangoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  # if Application.compile_env(:sase_mango, :dev_routes) do
  #   # If you want to use the LiveDashboard in production, you should put
  #   # it behind authentication and allow only admins to access it.
  #   # If your application does not have an admins-only section yet,
  #   # you can use Plug.BasicAuth to set up some basic authentication
  #   # as long as you are also using SSL (which you should anyway).
  #   import Phoenix.LiveDashboard.Router

  #   scope "/dev" do
  #     pipe_through :browser

  #     live_dashboard "/dashboard", metrics: SaseMangoWeb.Telemetry
  #   end
  # end

  defp admin_auth(conn, env: env) when env != :prod, do: conn

  defp admin_auth(conn, _opts) do
    options = Application.get_env(:sase_mango, :admin_auth)
    username = Keyword.fetch!(options, :username)
    password = Keyword.fetch!(options, :password)

    with {request_username, request_password} <- Plug.BasicAuth.parse_basic_auth(conn),
         valid_username? = Plug.Crypto.secure_compare(username, request_username),
         valid_password? = Plug.Crypto.secure_compare(password, request_password),
         true <- valid_username? and valid_password? do
      conn
    else
      _ -> conn |> Plug.BasicAuth.request_basic_auth() |> halt()
    end
  end
end
