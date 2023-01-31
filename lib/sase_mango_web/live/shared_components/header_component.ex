defmodule SaseMangoWeb.SharedComponents.HeaderComponent do
  @moduledoc """
  Component that renders page tabs with links
  """

  use SaseMangoWeb, :component

  def header(assigns) do
    ~H"""
    <div class="mx-12 xl:mx-16 mt-30 mb-0 md:mb-2 py-4">
      <div class="flex items-center gap-2 text-sm xl:text-base">
        <span class="text-page-tab-link font-normal">Date:</span>
        <.date_icon />
        <span class="font-normal"><%= todays_date() %></span>
      </div>

      <div class="w-full mt-8 flex items-end justify-start border-b border-gray-light">

        <div class="flex items-center w-full flex-row">
          <div class={"page-tab #{if @active_tab == :securities, do: "securities"}"} >
            <%= live_patch "List of securities", to: Routes.securities_index_path(@socket, :securities),
              class: "page-link"
            %>
            <div class="tab-line"></div>
          </div>
          <div class={"page-tab #{if @active_tab == :bargains, do: "bargains"}"}>
            <%= live_patch "Bargain securities", to: Routes.securities_index_path(@socket, :bargains),
              class: "page-link"
            %>
            <div class="tab-line"></div>
          </div>
          <div class={"page-tab #{if @active_tab == :calculator, do: "calculator"}"}>
            <%= live_redirect "Calculator", to: Routes.calculator_index_path(@socket, :index),
            class: "page-link" %>
            <div class="tab-line"></div>
          </div>
        </div>

      </div>
    </div>
    """
  end

  def date_icon(assigns) do
    ~H"""
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M11.6667 2.66663H2.33333C1.59695 2.66663 1 3.26358 1 3.99996V13.3333C1 14.0697 1.59695 14.6666 2.33333 14.6666H11.6667C12.403 14.6666 13 14.0697 13 13.3333V3.99996C13 3.26358 12.403 2.66663 11.6667 2.66663Z"
          stroke="#5B92D7"
          stroke-linecap="round"
          stroke-linejoin="round"
      />
      <path d="M9.66663 1.33337V4.00004" stroke="#5B92D7" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M4.33337 1.33337V4.00004" stroke="#5B92D7" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M1 6.66663H13" stroke="#5B92D7" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
    """
  end

  defp todays_date do
    {year, month, day} = DateTime.now!("Europe/Sarajevo") |> DateTime.to_date() |> Date.to_erl()
    "#{day}.#{month}.#{year}"
  end
end
