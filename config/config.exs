# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :halloween,
  ecto_repos: [Halloween.Repo],
  generators: [timestamp_type: :utc_datetime]

# Login (see Halloween.OIDC) and who hosts the party; set from env vars in config/runtime.exs.
config :halloween, :oidc, issuer: nil, client_id: nil, client_secret: nil
config :halloween, host_emails: []

# Where guests' photos are saved.
config :halloween, uploads_dir: Path.expand("../uploads", __DIR__)

# Configure the endpoint
config :halloween, HalloweenWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: HalloweenWeb.ErrorHTML, json: HalloweenWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Halloween.PubSub,
  live_view: [signing_salt: "+4Dzbx4l"]

# Configure LiveView
config :phoenix_live_view,
  # the attribute set on all root tags. Used for Phoenix.LiveView.ColocatedCSS.
  root_tag_attribute: "phx-r"

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
