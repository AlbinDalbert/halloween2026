defmodule Halloween.Uploads do
  @moduledoc "Guests' photos, saved under `:uploads_dir` and served at /uploads/:name."

  def dir, do: Application.fetch_env!(:halloween, :uploads_dir)

  @doc "Moves an uploaded file into the uploads dir and returns its new name."
  def save(tmp_path, extension) do
    name =
      "#{System.unique_integer([:positive])}-#{Base.url_encode64(:crypto.strong_rand_bytes(9))}#{extension}"

    File.mkdir_p!(dir())
    File.cp!(tmp_path, Path.join(dir(), name))
    name
  end
end
