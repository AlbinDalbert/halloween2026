defmodule HalloweenWeb.CoreComponents do
  @moduledoc "Form inputs and flash messages, styled by priv/static/assets/app.css."
  use Phoenix.Component

  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={
        Phoenix.LiveView.JS.push("lv:clear-flash", value: %{key: @kind})
        |> Phoenix.LiveView.JS.hide(to: "##{@id}")
      }
      role="alert"
      class={["flash", "flash-#{@kind}"]}
    >
      {msg}
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :type, :string, default: "text"
  attr :options, :list, default: [], doc: "for selects: `[{label, value}]`"
  attr :rest, :global, include: ~w(placeholder rows min max autocomplete autofocus maxlength)

  def input(%{type: "select"} = assigns) do
    ~H"""
    <label class="field">
      <span :if={@label}>{@label}</span>
      <select id={@field.id} name={@field.name} {@rest}>
        {Phoenix.HTML.Form.options_for_select(@options, @field.value)}
      </select>
      <.errors field={@field} />
    </label>
    """
  end

  # A list of strings, one per line.
  def input(%{type: "lines"} = assigns) do
    ~H"""
    <label class="field">
      <span :if={@label}>{@label}</span>
      <textarea id={@field.id} name={@field.name} {@rest}>{Enum.join(List.wrap(@field.value), "\n")}</textarea>
      <.errors field={@field} />
    </label>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <label class="field">
      <span :if={@label}>{@label}</span>
      <textarea id={@field.id} name={@field.name} {@rest}>{Phoenix.HTML.Form.normalize_value("textarea", @field.value)}</textarea>
      <.errors field={@field} />
    </label>
    """
  end

  def input(assigns) do
    ~H"""
    <label class="field">
      <span :if={@label}>{@label}</span>
      <input
        type={@type}
        id={@field.id}
        name={@field.name}
        value={Phoenix.HTML.Form.normalize_value(@type, @field.value)}
        {@rest}
      />
      <.errors field={@field} />
    </label>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true

  defp errors(assigns) do
    ~H"""
    <p :for={msg <- if(used_input?(@field), do: messages(@field), else: [])} class="field-error">
      {msg}
    </p>
    """
  end

  defp messages(field) do
    Enum.map(field.errors, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
      end)
    end)
  end
end
