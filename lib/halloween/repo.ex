defmodule Halloween.Repo do
  use Ecto.Repo,
    otp_app: :halloween,
    adapter: Ecto.Adapters.SQLite3
end
