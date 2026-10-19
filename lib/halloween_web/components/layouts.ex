defmodule HalloweenWeb.Layouts do
  @moduledoc "The page shells: `app/1` for guests and the TV, `host/1` for the host's pages."
  use HalloweenWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <main class={["shell", @class]}>
      {render_slot(@inner_block)}
    </main>
    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true
  attr :page, :atom, required: true, values: [:live, :decks, :guests]
  slot :inner_block, required: true

  def host(assigns) do
    ~H"""
    <nav class="host-nav">
      <span class="host-mark">{t("Host")}</span>
      <.link navigate={~p"/host"} aria-current={@page == :live && "page"}>{t("Live")}</.link>
      <.link navigate={~p"/host/decks"} aria-current={@page == :decks && "page"}>{t("Decks")}</.link>
      <.link navigate={~p"/host/guests"} aria-current={@page == :guests && "page"}>{t("Guests")}</.link>
      <span class="spacer"></span>
      <.link href={~p"/tv"} target="_blank">{t("TV")} ↗</.link>
      <.link navigate={~p"/"}>{t("My phone")}</.link>
    </nav>
    <main class="shell shell-host">
      {render_slot(@inner_block)}
    </main>
    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true

  def flash_group(assigns) do
    ~H"""
    <div id="flash-group" class="flash-group" aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end
end
