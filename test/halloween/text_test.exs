defmodule Halloween.TextTest do
  use ExUnit.Case, async: false
  alias Halloween.Text

  setup do
    on_exit(fn -> Application.put_env(:halloween, :language, "en") end)
  end

  test "every text in the app has a Swedish translation" do
    swedish = Halloween.Text.Swedish.strings()

    texts =
      for file <- Path.wildcard("lib/**/*.{ex,heex}"),
          [_, text] <- Regex.scan(~r/(?<![\w.])t\(\s*"((?:[^"\\]|\\.)*)"/, File.read!(file)),
          uniq: true,
          do: String.replace(text, ~S(\"), ~S("))

    # So a broken pattern can't pass by finding nothing.
    assert length(texts) > 100
    assert Enum.reject(texts, &Map.has_key?(swedish, &1)) == []
  end

  test "t/2 fills in values, in English or Swedish" do
    assert Text.t("%{n} of %{total} answered", n: 3, total: 5) == "3 of 5 answered"

    Application.put_env(:halloween, :language, "sv")
    assert Text.t("%{n} of %{total} answered", n: 3, total: 5) == "3 av 5 har svarat"
    assert Text.decimal(7.25) == "7,3"
  end
end
