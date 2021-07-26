defmodule SaseMangoWeb.SecuritiesLive do
  use SaseMangoWeb, :live_view

  alias SaseMango.Securities
  alias SaseMangoWeb.SecuritiesView

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign_new(socket, :securities, fn ->
        Securities.list_securities()
      end)

    {:ok, socket}
  end

  def render(assigns), do: SecuritiesView.render("index.html", assigns)
end
