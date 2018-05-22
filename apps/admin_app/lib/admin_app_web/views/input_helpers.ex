defmodule AdminAppWeb.InputHelpers do
  @moduledoc """
  Form helpers to generate form elements like input, checkbox, select(with select2)
  """
  use Phoenix.HTML
  alias AdminAppWeb.ErrorHelpers, as: EH
  alias Phoenix.HTML.Form

  def input(form, field, name \\ nil, opts \\ []) do
    type = Form.input_type(form, field)

    validate_required =
      form
      |> input_validations(field)
      |> check_required

    field_name = name || field
    wrapper_opts = [class: "form-group #{validate_required}"]
    label_opts = [class: "control-label"]

    input_opts = [class: "form-control #{state_class(form, field)}"] ++ opts

    content_tag :div, wrapper_opts do
      label = label(form, field, humanize(field_name), label_opts)
      input = apply(Form, type, [form, field, input_opts])
      error = EH.error_tag(form, field) || ""
      [label, input, error]
    end
  end

  def select_input(form, field, list, name \\ nil, opts \\ []) do
    validate_required =
      form
      |> input_validations(field)
      |> check_required

    field_name = name || field
    wrapper_opts = [class: "form-group #{validate_required}"]
    label_opts = [class: ""]

    input_opts =
      [class: "form-control  #{state_class(form, field)}", "data-init-plugin": "select2"] ++ opts

    content_tag :div, wrapper_opts do
      label = label(form, field, humanize(field_name), label_opts)
      select = select(form, field, list, input_opts)
      error = EH.error_tag(form, field) || ""
      [label, select, error || ""]
    end
  end

  def textarea_input(form, field, name \\ nil, opts \\ []) do
    field_name = name || field

    validate_required =
      form
      |> input_validations(field)
      |> check_required

    wrapper_opts = [class: "form-group #{validate_required}"]
    label_opts = [class: "control-label"]
    textarea_opts = [class: "form-control  #{state_class(form, field)}"] ++ opts

    content_tag :div, wrapper_opts do
      label = label(form, field, humanize(field_name), label_opts)
      input = textarea(form, field, textarea_opts)
      error = EH.error_tag(form, field) || ""
      [label, input, error || ""]
    end
  end

  def checkbox_input(form, field, name \\ nil, opts \\ []) do
    validate_required =
      form
      |> input_validations(field)
      |> check_required

    wrapper_opts = [
      class:
        "form-group form-group-default input-group cb-group #{validate_required} #{
          state_class(form, field)
        }"
    ]

    label_opts = [class: "inline"]
    field_name = name || field
    class = opts[:class] || ""
    input_opts = [class: class] ++ opts

    content_tag :div, wrapper_opts do
      label = label(form, field, humanize(field_name), label_opts)

      span_input =
        content_tag :label, class: "switch" do
          span = content_tag(:span, "", class: "slider round")
          input = checkbox(form, field, input_opts)
          error = EH.error_tag(form, field) || ""
          [input, span, error || ""]
        end

      [label, span_input]
    end
  end

  defp state_class(form, field) do
    cond do
      # The form was not yet submitted
      !form.source.action ->
        ""

      form.errors[field] ->
        "is-invalid"

      true ->
        "is-valid"
    end
  end

  def check_required(required: true), do: "required"
  def check_required(required: true, minlength: _), do: "required"
  def check_required(required: false), do: nil
  def check_required(required: false, minlength: _), do: nil
  def check_required([]), do: nil
end
