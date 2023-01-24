defmodule SaseMangoWeb.SharedComponents.IssuerSelectComponent do
  @moduledoc """
  Custom component that selects issuer smbol/name
  """

  use SaseMangoWeb, :live_component

  alias Phoenix.LiveView.JS
  alias SaseMangoWeb.SharedComponents.TableIconsComponent

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:suggestions, assigns.options)
     |> assign(:suggested_element, nil)
     |> assign(assigns)}
  end

  @impl true
  def handle_event("select_input_changed", %{"key" => key, "value" => value} = _params, socket) do
    %{options: options_from_socket} = socket.assigns

    search_value = String.downcase(value)

    case key do
      "Enter" ->
        if String.length(search_value) > 0, do: send(self(), {:update_state, search_value})

        {:noreply, socket}

      _value ->
        filtered_options =
          Enum.filter(options_from_socket, fn option ->
            String.starts_with?(String.downcase(option.symbol), search_value) ||
              String.starts_with?(String.downcase(option.name), search_value)
          end)

        suggested_element =
          if length(filtered_options) > 0 do
            first_issuer = List.first(filtered_options)

            is_suggested_by_symbol? =
              String.starts_with?(String.downcase(first_issuer.symbol), search_value)

            case is_suggested_by_symbol? do
              false -> first_issuer.name
              true -> first_issuer.symbol
            end
          end

        if String.length(value) > 0, do: send(self(), :update_state)

        {
          :noreply,
          socket
          |> assign(:suggested_element, suggested_element)
          |> assign(:suggestions, filtered_options)
        }
    end
  end

  def handle_event("select_input_changed", _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <div class="relative mt-1" phx-click-away={JS.hide(to: "#issuers-list")}>
        <div
          class="relative cursor-pointer w-full sm:min-w-[380px] px-[1rem] py-0 text-left bg-white border border-[#979797] hover:border-[#565555] rounded-[0.8rem] shadow-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 font-[300]"
          phx-click={JS.toggle(to: "#issuers-list")}
        >
            <%= if @issuer_input_cover do %>
              <div id="input-cover" class="z-[10] text-[0.86em] xl:text-[1.02em] bg-white flex items-center gap-2 text-left py-[0.9rem] mr-16"
                phx-hook="FieldReset"
              >
                <span class="block truncate text-[#5B92D7]"><%= @selected_issuer.symbol %></span>
                <span class="block truncate text-[#1E1E1E]"><%= @selected_issuer.name %></span>
              </div>
            <% end %>
            <div class={if(@issuer_input_cover, do: "", else: "relative")}>
              <input
                autocomplete="off"
                id="select-field"
                type="text"
                placeholder="SELECT"
                class={if(@issuer_input_cover, do: "absolute top-1 left-1 -z-[10]", else: "block") <> " border-0 p-[1rem] tracking-normal bg-transparent text-[1em] xl:text-[1.2em] font-[300] pr-8 placeholder:focus:text-transparent"}
                phx-keyup="select_input_changed"
                phx-target={@myself}
              />
            </div>

            <span class={"absolute " <> if(@suggested_element, do: "opacity-60", else: "opacity-0") <> " top-1/2 -translate-y-1/2 pl-[1rem] tracking-normal text-[1em] xl:text-[1.2em] font-[300] text-[#a3a3a3]"} >
              <%= @suggested_element %>
            </span>

            <span class="absolute inset-y-0 right-0 flex items-center pr-4 ml-3">
              <TableIconsComponent.arrow_down />
            </span>
        </div>
          <ul id="issuers-list"
            class="absolute hidden z-[10] w-full sm:min-w-[380px] py-1 mt-2 overflow-y-auto text-[1em] font-[300] max-h-[34rem] bg-white shadow-lg rounded-lg ring-1 ring-gray-400 ring-opacity-25 focus:outline-none"
            role="selectable-options"
          >
            <%= for suggestion <- @suggestions do %>
              <li
                class="relative select-none"
                role="option"
                phx-click={JS.push("select_issuer", value: %{symbol: suggestion.symbol}) |> JS.hide(to: "#issuers-list")}
              >
                <div class="w-full flex flex-col gap-2 py-2 pl-3 pr-9 border-b border-gray-100 cursor-pointer hover:bg-sky-100"
                >
                  <span class="block ml-3 font-normal text-[#5B92D7]">
                    <%= suggestion.symbol %>
                  </span>
                  <span class="w-max block ml-3 font-normal text-[#1E1E1E]">
                    <%= suggestion.name %>
                  </span>
                </div>
              </li>
            <% end %>
          </ul>
      </div>
    </div>
    """
  end
end
