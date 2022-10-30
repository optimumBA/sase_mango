defmodule SaseMangoWeb.SecuritiesLive.TableRowComponent do
  @moduledoc """
    Component that renders securitity table row
  """

  use SaseMangoWeb, :component

  def table_row(assigns) do
    ~H"""
      <%= case @live_action do %>
        <% :bargains -> %>
          <tr
              id={"security-#{@security.symbol}"}
              class={"#{if @security.newest, do: " bg-[#E3F2FF]", else: if(@security.new, do: " bg-[#F8F9FA]", else: "") }"}
            >
            <%= render_slot(@inner_block) %>
          </tr>
        <% :securities -> %>
          <tr id={"security-#{@security.symbol}"}>
            <%= render_slot(@inner_block) %>
          </tr>
      <% end %>
    """
  end
end
