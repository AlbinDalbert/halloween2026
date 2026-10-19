defmodule HalloweenWeb.AuthController do
  use HalloweenWeb, :controller
  require Logger
  alias Halloween.{Game, OIDC}

  def new(conn, _params) do
    if conn.assigns.current_user do
      redirect(conn, to: ~p"/")
    else
      render(conn, :new, page_title: "Enter")
    end
  end

  def login(conn, _params) do
    state = OIDC.random_token()
    verifier = OIDC.random_token()

    with true <- OIDC.configured?(),
         {:ok, url} <- OIDC.authorize_url(url(~p"/auth/callback"), state, verifier) do
      conn
      |> put_session(:oidc, %{state: state, verifier: verifier})
      |> redirect(external: url)
    else
      false ->
        failed(
          conn,
          "Login isn't set up: OIDC_ISSUER, OIDC_CLIENT_ID or OIDC_CLIENT_SECRET is missing."
        )

      error ->
        failed(conn, "Couldn't reach the login provider. Try again.", error)
    end
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    with %{state: ^state, verifier: verifier} <- get_session(conn, :oidc),
         {:ok, profile} <- OIDC.sign_in(code, url(~p"/auth/callback"), verifier),
         {:ok, user} <- Game.login(profile, Application.get_env(:halloween, :host_emails)) do
      log_in(conn, user)
    else
      error -> failed(conn, "Login didn't work. Try again.", error)
    end
  end

  def callback(conn, params), do: failed(conn, "Login didn't work. Try again.", params)

  @doc """
  Development only: log in as anyone with /dev/login?name=Morticia, let in at once. `host` is
  a host; add `&wait` to wait at the door instead.
  """
  def dev_login(conn, %{"name" => name}) do
    {:ok, user} = Game.login(%{id: "dev-#{name}", email: "#{name}@dev"}, ["host@dev"])
    {:ok, user} = if user.name, do: {:ok, user}, else: Game.set_name(user, %{name: name})
    # `&wait` leaves them at the door, to try letting people in.
    {:ok, user} = if conn.params["wait"], do: {:ok, user}, else: Game.let_in(user)
    log_in(conn, user)
  end

  def logout(conn, _params) do
    conn |> configure_session(drop: true) |> redirect(to: ~p"/login")
  end

  defp log_in(conn, user) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> put_session(:user_id, user.id)
    |> redirect(to: ~p"/")
  end

  defp failed(conn, message, error \\ nil) do
    if error, do: Logger.warning("Login failed: #{inspect(error)}")

    conn
    |> put_flash(:error, message)
    |> redirect(to: ~p"/login")
  end
end
