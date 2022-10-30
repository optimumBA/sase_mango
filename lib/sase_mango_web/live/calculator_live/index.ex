defmodule SaseMangoWeb.CalculatorLive.Index do
  use SaseMangoWeb, :live_view

  alias Phoenix.Socket.Broadcast
  alias SaseMango.Calculator
  alias SaseMango.SecuritiesCache
  alias SaseMangoWeb.Endpoint
  alias SaseMangoWeb.SharedComponents.CustomSelectComponent
  alias SaseMangoWeb.SharedComponents.FormComponents
  alias SaseMangoWeb.SharedComponents.HeaderComponent
  alias SaseMangoWeb.SharedComponents.TableIconsComponent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:changeset, Calculator.change_input(%Calculator.Input{}))
      |> assign_results()
      |> assign(:securities, SecuritiesCache.get_securities())
      |> assign(:active_tab, :calculator)
      |> assign(:select_open, false)
      |> assign(:select_item, %{symbol: "", name: ""})
      |> assign(:input_flip, false)
      |> assign_select_list()

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
  def handle_event("calculate", %{"input" => input_params}, socket) do
    {:noreply,
     socket
     |> reassign_changeset(input_params)
     |> calculate()}
  end

  def handle_event("validate", %{"input" => input_params}, socket) do
    {:noreply, reassign_changeset(socket, input_params)}
  end

  def handle_event("toggle", _params, socket) do
    {:noreply, assign(socket, :select_open, !socket.assigns.select_open)}
  end

  def handle_event("hide_select", _params, socket) do
    input_flip = if String.length(socket.assigns.select_item.name) > 0, do: true, else: false

    {:noreply,
     socket
     |> assign(:select_open, false)
     |> assign(:input_flip, input_flip)}
  end

  def handle_event("input_flip", _, socket) do
    {:noreply, assign(socket, :input_flip, !socket.assigns.input_flip)}
  end

  def handle_event("custom_select", %{"symbol" => symbol} = _params, socket) do
    selected_item = Enum.find(socket.assigns.select_list, &(&1.symbol == symbol))

    changeset_from_socket = socket.assigns.changeset

    changes_from_socket = Map.merge(changeset_from_socket.changes, %{symbol: symbol})

    changeset =
      %Calculator.Input{}
      |> Calculator.change_input(changes_from_socket)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:select_open, false)
     |> assign(:input_flip, true)
     |> assign(:select_item, selected_item)}
  end

  def handle_event("delete_row", %{"row_id" => row_id} = _params, socket) do
    socket_results = socket.assigns.results

    target_row = Enum.find(socket_results.securities, &(&1.id == row_id))
    new_rows = Enum.filter(socket_results.securities, &(&1.id != row_id))

    new_results = %{
      securities: new_rows,
      total_without_fee:
        Decimal.sub(socket_results.total_without_fee, target_row.total_without_fee),
      total_with_fee: Decimal.sub(socket_results.total_with_fee, target_row.total_with_fee)
    }

    {:noreply, assign(socket, :results, new_results)}
  end

  @impl true
  def handle_info(%Broadcast{event: "securities_update"}, socket) do
    securities = SecuritiesCache.get_securities()

    {:noreply,
     socket
     |> assign(:securities, securities)
     |> calculate()}
  end

  def handle_info({:update_state}, socket) do
    {:noreply,
     socket
     |> assign(:select_open, true)
     |> assign(:input_flip, false)
     |> assign(:select_item, %{symbol: "", name: ""})}
  end

  def handle_info({:update_state, value}, socket) do
    selected_item =
      Enum.find(
        socket.assigns.select_list,
        &(String.starts_with?(&1.symbol, value) || String.starts_with?(&1.name, value))
      )

    case selected_item do
      nil ->
        {
          :noreply,
          socket
          |> assign(:select_open, false)
          |> assign(:input_flip, false)
        }

      selected_item ->
        changeset_from_socket = socket.assigns.changeset

        changes_from_socket =
          Map.merge(changeset_from_socket.changes, %{symbol: selected_item.symbol})

        changeset =
          %Calculator.Input{}
          |> Calculator.change_input(changes_from_socket)
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(:changeset, changeset)
         |> assign(:select_open, false)
         |> assign(:input_flip, true)
         |> assign(:select_item, selected_item)}
    end
  end

  def assign_select_list(socket) do
    securities = socket.assigns.securities

    select_list =
      Enum.reduce(securities, [], fn %{symbol: symbol, name: name} = _security, select_list ->
        [%{symbol: symbol, name: name} | select_list]
      end)

    assign(socket, :select_list, select_list)
  end

  defp reassign_changeset(socket, input_params) do
    select_item = socket.assigns.select_item

    changeset_params = Map.merge(input_params, %{"symbol" => select_item.symbol})

    changeset =
      %Calculator.Input{}
      |> Calculator.change_input(changeset_params)
      |> Map.put(:action, :validate)

    assign(socket, :changeset, changeset)
  end

  defp calculate(socket) do
    socket_results = socket.assigns.results

    case Ecto.Changeset.apply_action(socket.assigns.changeset, :insert) do
      {:ok, input} ->
        assign(
          socket,
          :results,
          Calculator.maybe_add_item(socket.assigns.securities, socket_results, input)
        )

      {:error, changeset} ->
        assign(socket, :changeset, changeset)
    end
  end
end
