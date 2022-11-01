defmodule SaseMangoWeb.SecuritiesLive.TableRowComponent do
  @moduledoc """
  Component that renders securitity table row
  """

  use SaseMangoWeb, :component

  def table_row(%{security: security} = assigns) do
    class =
      cond do
        security[:newest] ->
          "bg-[#E3F2FF]"

        security[:new] ->
          "bg-[#F8F9FA]"

        true ->
          ""
      end

    ~H"""
    <tr class={class} id={"security-" <> @security.symbol}>
      <%= render_slot(@inner_block) %>
    </tr>
    """
  end
end
