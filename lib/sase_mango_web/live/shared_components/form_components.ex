defmodule SaseMangoWeb.SharedComponents.FormComponents do
  @moduledoc """
  Helper module with form components
  """

  use SaseMangoWeb, :component

  def input_wrapper(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:error_tag, fn -> false end)
      |> assign_new(:phx_feedback_for, fn -> input_name(assigns.form, assigns.field) end)
      |> assign_new(:required, fn -> false end)
      |> assign_new(:show_feedback, fn -> false end)

    ~H"""
    <div class={@class}
      id={input_id(@form, @field) <> "_wrapper"}
      phx-feedback-for={@phx_feedback_for}>
      <%= label @form, @field, class: if(@show_feedback,
          do: label_class(@form, @field),
          else: "mb-[0.5rem] text-sm xl:text-base text-gray-450")
      do %>
        <%= @label %>
      <% end %>

      <%= render_slot(@inner_block) %>

      <%= if @error_tag do %>
        <%= error_tag @form, @field %>
      <% end %>
    </div>
    """
  end

  def label_class(form, field),
    do:
      if(field_has_error?(form, field),
        do: "mb-[0.5rem] text-sm xl:text-base text-red-700 label-invalid",
        else: "mb-[0.5rem] text-sm xl:text-base text-gray-450"
      )

  @spec field_has_error?(atom | %{:errors => keyword, optional(any) => any}, atom) :: boolean
  def field_has_error?(form, field) do
    Keyword.has_key?(form.errors, field)
  end

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
