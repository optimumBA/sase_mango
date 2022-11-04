defmodule SaseMangoWeb.SecuritiesLive.FilterFormComponent do
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
    <div>
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
          <%= text_input f, :q, phx_debounce: 400, placeholder: "Search...", class: "search-field" %>
          <div class="search-icons">
            <%= if !is_nil(@filter.q) && String.length(@filter.q) > 0 do %>
              <div class="cursor-pointer text-[#ADADAD] hover:text-[#565555]" phx-click="clear_form">
                <svg
                  width="12"
                  height="12"
                  viewBox="0 0 10 10"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path d="M9 1L1 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                  <path d="M1 1L9 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </div>
              <% end %>
            <div>
              <svg
                width="28"
                height="20"
                viewBox="0 0 24 16"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <rect width="1" height="16" fill="#D9D9D9"/>
                <path d="M16.3333 12.6667C19.2789 12.6667 21.6667 10.2789 21.6667 7.33333C21.6667 4.38781 19.2789 2 16.3333 2C13.3878 2 11 4.38781 11 7.33333C11 10.2789 13.3878 12.6667 16.3333 12.6667Z"
                  stroke="#ADADAD"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
                <path d="M23 14L20.1 11.1"
                  stroke="#ADADAD"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
              </svg>
            </div>
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
