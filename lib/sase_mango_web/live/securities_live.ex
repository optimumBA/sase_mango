defmodule SaseMangoWeb.SecuritiesLive do
  use SaseMangoWeb, :live_view

  alias Phoenix.Socket.Broadcast
  alias SaseMango.SecuritiesCache
  alias SaseMangoWeb.{Endpoint, SecuritiesView}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign_new(socket, :securities, fn ->
        SecuritiesCache.get()
      end)

    if connected?(socket) do
      Endpoint.subscribe("securities")
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns), do: SecuritiesView.render("index.html", assigns)

  @impl true
  def handle_info(%Broadcast{event: "securities_update"}, socket) do
    securities = SecuritiesCache.get()
    {:noreply, assign(socket, :securities, securities)}
  end
end
