defmodule SaseMangoWeb.SharedComponents.HeaderComponent do
  @moduledoc """
  Component that renders page tabs with links
  """

  use SaseMangoWeb, :html

  alias SaseMango.SecuritiesHelper

  @doc """
  Renders the header component with navigation links.

  ## Examples

      <.header active_tab={@active_tab} />
  """
  attr :active_tab, :atom, required: true

  def header(assigns) do
    ~H"""
    <div class="mx-12 xl:mx-16 pt-30 mb-0 md:mb-2 pb-4 max-h-[30vh]">
      <div class="flex items-center gap-2 text-sm xl:text-base">
        <span class="text-gray-450 font-normal">Date:</span>
        <.date_icon />
        <span class="font-normal"><%= SecuritiesHelper.format_date() %></span>
      </div>

      <div class="w-full mt-4 flex items-end justify-start border-b border-gray-350">
        <div class="flex items-center w-full flex-row">
          <div
            :for={item <- header_items()}
            class={"page-tab #{if @active_tab == item.id, do: item.class_name}"}
          >
            <.link patch={item.path} class="page-link"><%= item.title %></.link>
            <div class="tab-line"></div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp header_items() do
    [
      %{id: :securities, title: "List of securities", path: ~p"/", class_name: "securities"},
      %{id: :bargains, title: "Bargain securities", path: ~p"/bargains", class_name: "bargains"},
      %{id: :investors_list, title: "List of Investors", path: ~p"/investors", class_name: "investors_list"},
      %{id: :calculator, title: "Calculator", path: ~p"/calculator", class_name: "calculator"}
    ]
  end

  defp date_icon(assigns) do
    ~H"""
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path
        d="M11.6667 2.66663H2.33333C1.59695 2.66663 1 3.26358 1 3.99996V13.3333C1 14.0697 1.59695 14.6666 2.33333 14.6666H11.6667C12.403 14.6666 13 14.0697 13 13.3333V3.99996C13 3.26358 12.403 2.66663 11.6667 2.66663Z"
        stroke="#5B92D7"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
      <path
        d="M9.66663 1.33337V4.00004"
        stroke="#5B92D7"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
      <path
        d="M4.33337 1.33337V4.00004"
        stroke="#5B92D7"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
      <path d="M1 6.66663H13" stroke="#5B92D7" stroke-linecap="round" stroke-linejoin="round" />
    </svg>
    """
  end
end
