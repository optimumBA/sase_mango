defmodule SaseMangoWeb.CalculatorLive.Index do
  use SaseMangoWeb, :live_view

  alias Phoenix.Socket.Broadcast
  alias SaseMango.Calculator
  alias SaseMango.Securities
  alias SaseMangoWeb.Components.CustomSelectComponent
  alias SaseMangoWeb.Components.HeaderComponent
  alias SaseMangoWeb.Components.TableIconsComponent
  alias SaseMangoWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:changeset, Calculator.change_input(%Calculator.Input{}))
      |> assign_results()
      |> assign(:securities, Securities.list_securities(:bargains))
      |> assign(:active_tab, :calculator)
      |> assign(:select_open, false)
      |> assign(:select_item, %{key: "", value: nil})
      |> get_select_list()

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
    select_item = socket.assigns.select_item

    changeset = Calculator.change_input(%Calculator.Input{}, input_params)

    changes = Map.merge(changeset.changes, %{symbol: select_item.key})

    changeset =
      changeset
      |> Map.put(:changes, changes)
      |> Map.put(:action, :validate)

    IO.inspect(changeset)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("toggle", _params, socket) do
    {:noreply, assign(socket, :select_open, !socket.assigns.select_open)}
  end

  def handle_event("hide_select", _params, socket) do
    {:noreply, assign(socket, :select_open, false)}
  end

  def handle_event("custom_select", %{"symbol" => symbol} = _params, socket) do
    selected_item = Enum.find(socket.assigns.select_list, &(&1.key == symbol))

    {:noreply,
     socket
     |> assign(:select_open, false)
     |> assign(:select_item, selected_item)}
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
    securities = Securities.list_securities(:bargains)

    {:noreply,
     socket
     |> assign(:securities, securities)
     |> calculate()}
  end

  def get_select_list(socket) do
    securities = socket.assigns.securities

    select_list =
      Enum.reduce(securities, [], fn %{symbol: symbol, name: name} = _security, select_list ->
        [%{key: symbol, value: name} | select_list]
      end)

    assign(socket, :select_list, select_list)
  end

  def enable_form_submit?(changeset), do: changeset.valid?
  def enable_forms_fields?(select_item) when is_binary(select_item.key), do: String.length(select_item.key) > 0
  def enable_forms_fields?(_select_item), do: false

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
