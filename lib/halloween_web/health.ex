defmodule HalloweenWeb.Health do
  @moduledoc "Answers Kubernetes probes on /healthz before anything else runs."
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(%{request_path: "/healthz"} = conn, _opts) do
    conn |> send_resp(200, "ok") |> halt()
  end

  def call(conn, _opts), do: conn
end
