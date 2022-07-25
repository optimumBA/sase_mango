defmodule SaseMangoWeb.CalculatorLive do
  use SaseMangoWeb, :live_view

  alias Phoenix.Socket.Broadcast
  alias SaseMango.{Calculator}
  alias SaseMangoWeb.{CalculatorView, Endpoint}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_new(:changeset, fn -> Calculator.change_input(%Calculator.Input{}) end)
      |> assign_new(:result, fn -> %{} end)
      |> assign_new(:securities, fn -> SaseMango.Securities.list_securities() end)

    if connected?(socket) do
      Endpoint.subscribe("securities")
    end

    {:ok, calculate(socket)}
  end

  @impl true
  def render(assigns), do: CalculatorView.render("index.html", assigns)

  @impl true
  def handle_event("calculate", %{"input" => input_params}, socket) do
    changeset =
      %Calculator.Input{}
      |> Calculator.change_input(input_params)
      |> Map.put(:action, :insert)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> calculate()}
  end

  @impl true
  def handle_info(%Broadcast{event: "securities_update"}, socket) do
    securities = SaseMango.Securities.list_securities()

    {:noreply,
     socket
     |> assign(:securities, securities)
     |> calculate()}
  end

  defp calculate(socket) do
    case Ecto.Changeset.apply_action(socket.assigns.changeset, :insert) do
      {:ok, input} ->
        result = Calculator.run(socket.assigns.securities, input)
        assign(socket, :result, result)

      {:error, changeset} ->
        assign(socket, :changeset, changeset)
    end
  end
end
