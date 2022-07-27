defmodule SaseMangoWeb.CalculatorLive.Index do
  use SaseMangoWeb, :live_view

  alias Phoenix.Socket.Broadcast
  alias SaseMango.Calculator
  alias SaseMango.Securities
  alias SaseMangoWeb.Components.HeaderComponent
  alias SaseMangoWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:changeset, Calculator.change_input(%Calculator.Input{}))
      |> assign_results()
      |> assign(:securities, Securities.list_securities(:bargains))
      |> assign(:active_tab, :calculator)
      |> get_symbols_list()

    if connected?(socket) do
      Endpoint.subscribe("securities")
    end

    {:ok, calculate(socket)}
  end

  defp assign_results(socket) do
    results = %{
      securities: [],
      total_without_fee: Decimal.new(0),
      total_with_fee: Decimal.new(0)
    }

    assign(socket, :results, results)
  end

  @impl true
  def handle_event("validate", %{"input" => input_params}, socket) do
    changeset =
      %Calculator.Input{}
      |> Calculator.change_input(input_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

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
    securities = Securities.list_securities(:bargains)

    {:noreply,
     socket
     |> assign(:securities, securities)
     |> calculate()}
  end

  def get_symbols_list(socket) do
    securities = socket.assigns.securities

    symbols_list =
      Enum.reduce(securities, [], fn %{symbol: symbol, name: name} = _security, symbol_list ->
        [[key: symbol <> "-" <> name, value: symbol] | symbol_list]
      end)

    assign(socket, :symbols_list, symbols_list)
  end

  defp calculate(socket) do
    case Ecto.Changeset.apply_action(socket.assigns.changeset, :insert) do
      {:ok, input} ->
        result = Calculator.run(socket.assigns.securities, input)

        total_without_fee =
          Decimal.add(socket.assigns.results.total_without_fee, result.total_without_fee)

        total_with_fee = Decimal.add(socket.assigns.results.total_with_fee, result.total_with_fee)

        new_results = %{
          securities: [result | socket.assigns.results.securities],
          total_without_fee: total_without_fee,
          total_with_fee: total_with_fee
        }

        assign(socket, :results, new_results)

      {:error, changeset} ->
        assign(socket, :changeset, changeset)
    end
  end
end
