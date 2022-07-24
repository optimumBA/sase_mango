defmodule SaseMangoWeb.Plugs.WelcomePageRedirector do
  # alias SaseMangoWeb.Router.Helpers, as: Routes

  @spec init(Keyword.t()) :: Keyword.t()
  def init([to: _path] = opts), do: opts

  def init(_opts), do: raise("Missing required to: / path: option in redirect")

  @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def call(conn, [to: path] = _opts) do
    conn
    |> Phoenix.Controller.redirect(to: path)
    |> Plug.Conn.halt()
  end
end
