defmodule SaseMangoWeb.Components.FilterFormComponent do
  use SaseMangoWeb, :live_component

  alias SaseMango.HandleTable
  alias SaseMango.HandleTable.SearchFilter

  def update(assigns, socket) do
    {:ok,
     socket
     |> filter_changeset(assigns)
     |> assign(assigns)}
  end

  defp filter_changeset(socket, %{filter: filter} = _assigns) do
    assign(socket, :changeset, HandleTable.change_table_filter(filter))
  end

  def handle_event("validate_filter", %{"filter" => %{"q" => filter_value}}, socket) do
    :timer.sleep(500)

    changeset =
      %SearchFilter{}
      |> HandleTable.change_table_filter(%{q: filter_value})
      |> Map.put(:action, :insert)

    send_msg_to_parent(filter_value)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp send_msg_to_parent(filter_value) do
    case String.length(filter_value) > 0 do
      true -> send(self(), {:url_update, %{q: filter_value}})
      false -> send(self(), {:url_update, %{q: nil}})
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center gap-6">
      <.form
        let={f}
        for={@changeset}
        as="filter"
        phx-submit="validate_filter"
        phx-change="validate_filter"
        phx-target={@myself}
        class="table-form"
      >
        <div>
          <%= text_input f, :q, phx_debounce: 500, placeholder: "Search ...", class: "search-field" %>
          <div class="search-icon">
            <svg width="18" height="18"
              viewBox="0 0 14 14" fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M6.33333 11.6667C9.27885 11.6667 11.6667 9.27885 11.6667 6.33333C11.6667 3.38781 9.27885 1 6.33333 1C3.38781 1 1 3.38781 1 6.33333C1 9.27885 3.38781 11.6667 6.33333 11.6667Z"
                stroke="#ADADAD" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              <path d="M13.0001 13L10.1001 10.1"
                stroke="#ADADAD" stroke-width="2"
                stroke-linecap="round" stroke-linejoin="round"
              />
            </svg>
          </div>
        </div>
      </.form>
      <div>
        <svg width="26" height="18" viewBox="0 0 26 18" fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path d="M19.6667 9L6.33337 9" stroke="#ADADAD" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M23.6667 2.33337L2.33337 2.33337" stroke="#ADADAD" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M15.6667 15.6666H10.3334" stroke="#ADADAD" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </div>
    </div>
    """
  end
end
