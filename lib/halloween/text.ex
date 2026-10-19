defmodule Halloween.Text do
  @moduledoc """
  The app's words, in English or Swedish (`PARTY_LANGUAGE`: `en` or `sv`).

  English is written where it's used, wrapped in `t/2`. When the party is in Swedish, `t/2`
  looks the English up in `Halloween.Text.Swedish`. A missing translation falls back to
  English, and a test checks that there are none.

      t("Your cards")
      t("%{n} of %{total} answered", n: 3, total: 5)
  """
  @swedish Halloween.Text.Swedish.strings()

  def language, do: Application.get_env(:halloween, :language, "en")

  def t(text, bindings \\ []) do
    text = if language() == "sv", do: Map.get(@swedish, text, text), else: text

    Enum.reduce(bindings, text, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  @doc "A decimal number the way the party's language writes it: 7.5 or 7,5."
  def decimal(number) do
    text = :erlang.float_to_binary(number / 1, decimals: 1)
    if language() == "sv", do: String.replace(text, ".", ","), else: text
  end
end
