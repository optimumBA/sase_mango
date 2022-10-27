defmodule SaseMangoWeb.SharedComponents.FormComponents do
  use SaseMangoWeb, :component

  def submit_button(%{changeset: %Ecto.Changeset{valid?: valid?}, class: class} = assigns) do
    attrs =
      if valid? do
        [class: class]
      else
        [class: class <> " disabled", disabled: true]
      end

    ~H"""
      <%= submit(@text, attrs) %>
    """
  end
end
