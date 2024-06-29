defmodule SaseMangoWeb.SharedComponents.IssuerSelectComponent do
  @moduledoc """
  Custom component selects issuer symbol/name
  """

  use SaseMangoWeb, :live_component

  alias Phoenix.LiveView.JS
  alias SaseMangoWeb.SharedComponents.TableIconsComponent

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:suggestions, Enum.with_index(assigns.options))
     |> assign(:suggested_element, nil)
     |> assign(:idx, -1)
     |> assign(:maxIdx, Enum.count(assigns.options) - 1)
     |> assign(assigns)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("select_input_changed", %{"key" => key, "value" => value} = _params, socket) do
    %{options: options_from_socket} = socket.assigns

    search_value = String.downcase(value)

    cond do
      key in ["Enter", "Tab"] ->
        if socket.assigns.idx != -1 do
          {selected_issuer, _idx} =
            Enum.find(socket.assigns.suggestions, fn {_issuer, idx} ->
              idx == socket.assigns.idx
            end)

          send(
            self(),
            {:select_issuer, %{symbol: selected_issuer.symbol, name: selected_issuer.name}}
          )
        else
          send(self(), {:update_state, search_value})
        end

        {:noreply, socket}

      true ->
        filtered_options =
          options_from_socket
          |> Enum.filter(fn option ->
            String.contains?(String.downcase(option.symbol), search_value) ||
              String.contains?(String.downcase(option.name), search_value)
          end)
          |> Enum.with_index()

        if String.length(value) > 0 do
          suggested_element =
            if length(filtered_options) > 0 do
              {first_issuer, _idx} = List.first(filtered_options)

              is_suggested_by_symbol? =
                String.contains?(String.downcase(first_issuer.symbol), search_value)

              case is_suggested_by_symbol? do
                false -> first_issuer.name
                true -> first_issuer.symbol
              end
            end

          send(self(), :update_state)

          {:noreply,
           socket
           |> assign(:suggested_element, suggested_element)
           |> assign(:maxIdx, Enum.count(filtered_options) - 1)
           |> assign(:suggestions, filtered_options)}
        else
          {:noreply,
           socket
           |> assign(:suggested_element, nil)
           |> assign(:maxIdx, Enum.count(filtered_options) - 1)
           |> assign(:suggestions, filtered_options)}
        end
    end
  end

  def handle_event("scroll_list", %{"key" => key} = _params, socket) do
    old_idx = socket.assigns.idx
    maxIdx = socket.assigns.maxIdx

    newIdx =
      case key do
        "ArrowUp" ->
          if(old_idx <= 0, do: maxIdx, else: old_idx - 1)

        "ArrowDown" ->
          if(old_idx == maxIdx, do: 0, else: old_idx + 1)
      end

    {:noreply,
     socket
     |> assign(:idx, newIdx)}
  end

  defp hide_issuers_list(js \\ %JS{}) do
    JS.hide(js, to: "#issuers-list", transition: "fade-out-scale")
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id="issuer-select-comp">
      <div class="relative mt-1">
        <div
          class="relative cursor-pointer w-95 h-11 flex flex-col justify-center px-4 py-2 text-left bg-white border border-gray-450 hover:border-gray-600 rounded-[0.6rem] shadow-sm focus:outline-none font-light"
          phx-click={JS.toggle(to: "#issuers-list")}
          phx-click-away={hide_issuers_list()}
        >
          <%= if @issuer_input_cover do %>
            <div
              id="input-cover"
              class="z-10 text-sm xl:text-base bg-white flex items-center gap-2 text-left py-0 mr-8"
              phx-hook="FieldReset"
            >
              <span class="block text-blue-dark-500"><%= @selected_issuer.symbol %></span>
              <span class="block truncate text-gray-800"><%= @selected_issuer.name %></span>
            </div>
          <% end %>
          <div class={if(@issuer_input_cover, do: "", else: "relative")}>
            <input
              autocomplete="off"
              id="select-field"
              type="text"
              placeholder="SELECT"
              class={if(@issuer_input_cover, do: "absolute top-1 left-1 -z-10", else: "block") <> " border-0 px-1 py-0 tracking-normal bg-transparent text-sm xl:text-base font-light pr-8 placeholder:focus:text-transparent"}
              phx-hook="InputField"
              phx-blur={hide_issuers_list()}
              phx-target={@myself}
            />
          </div>

          <span
            class={"absolute " <> if(@suggested_element, do: "opacity-60", else: "opacity-0") <> " top-1/2 -translate-y-1/2 pl-1 tracking-normal text-sm xl:text-base font-light text-gray-450"}
            {if(@suggested_element, do: [phx_click: JS.push("select_issuer", value: %{symbol: @suggested_element}) |> hide_issuers_list()], else: [])}
          >
            <%= @suggested_element %>
          </span>

          <span class="absolute inset-y-0 right-0 flex items-center pr-4 ml-3">
            <TableIconsComponent.arrow_down />
          </span>
        </div>

        <ul
          id="issuers-list"
          class="absolute hidden z-10 w-full sm:min-w-96 py-1 mt-2 overflow-y-auto text-base font-light max-h-94 bg-white shadow-lg rounded-lg ring-1 ring-gray-400 ring-opacity-25 focus:outline-none"
          role="listbox"
        >
          <%= unless Enum.empty?(@suggestions) do %>
            <%= for {suggestion, idx} <- @suggestions do %>
              <li
                class="relative m-0"
                role="option"
                phx-click={
                  JS.push("select_issuer", value: %{symbol: suggestion.symbol}) |> hide_issuers_list()
                }
              >
                <div class={"w-full flex flex-col gap-2 py-2 pl-3 pr-3 border-b border-gray-100 cursor-pointer #{if(@idx == idx, do: "bg-sky-100", else: "")} hover:bg-sky-100"}>
                  <span class="block ml-3 font-normal text-blue-dark-500">
                    <%= suggestion.symbol %>
                  </span>
                  <span class="block ml-3 font-normal text-gray-800">
                    <%= suggestion.name %>
                  </span>
                </div>
              </li>
            <% end %>
          <% else %>
            <li class="relative m-0">
              <span class="block ml-3 py-2 text-sm xl:text-base font-normal text-blue-dark-500">
                No results
              </span>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end
end
