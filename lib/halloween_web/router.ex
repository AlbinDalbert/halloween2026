defmodule HalloweenWeb.Router do
  use HalloweenWeb, :router
  import HalloweenWeb.UserAuth, only: [fetch_user: 2, require_user: 2, require_approved: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HalloweenWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_user
  end

  scope "/", HalloweenWeb do
    pipe_through :browser

    get "/login", AuthController, :new
    get "/auth/login", AuthController, :login
    get "/auth/callback", AuthController, :callback
    post "/logout", AuthController, :logout
  end

  scope "/", HalloweenWeb do
    pipe_through [:browser, :require_user]

    # Someone new waits here, at the door, until a host lets them in.
    live_session :guest, on_mount: {HalloweenWeb.UserAuth, :guest} do
      live "/", GuestLive
    end

    live_session :approved, on_mount: {HalloweenWeb.UserAuth, :approved} do
      live "/tv", TvLive
    end

    live_session :host, on_mount: {HalloweenWeb.UserAuth, :host} do
      live "/host", HostLive
      live "/host/decks", DecksLive
      live "/host/decks/:id", DeckLive
      live "/host/guests", GuestsLive
    end
  end

  scope "/", HalloweenWeb do
    pipe_through [:browser, :require_user, :require_approved]

    get "/uploads/:name", UploadController, :show
  end

  if Application.compile_env(:halloween, :dev_routes) do
    scope "/dev", HalloweenWeb do
      pipe_through :browser

      get "/login", AuthController, :dev_login
    end
  end
end
