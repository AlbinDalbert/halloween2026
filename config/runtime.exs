import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# In development, load `.env` (see example.env) into the environment, so `mix phx.server` picks
# it up without exporting anything first. Variables already set in the shell win, so one-off
# overrides like `PORT=4001 mix phx.server` still work. Releases and tests never read it.
# Format: `KEY=value` lines; blank lines, `#` comments, and an `export ` prefix are allowed,
# and a value may be wrapped in single or double quotes.
if config_env() == :dev and File.exists?(".env") do
  for line <- File.stream!(".env"),
      line = String.trim(line),
      line != "" and not String.starts_with?(line, "#"),
      [key, value] <- [
        line |> String.replace_prefix("export ", "") |> String.split("=", parts: 2)
      ],
      key = String.trim(key),
      is_nil(System.get_env(key)) do
    value =
      case String.trim(value) do
        "\"" <> rest -> String.trim_trailing(rest, "\"")
        "'" <> rest -> String.trim_trailing(rest, "'")
        value -> value
      end

    System.put_env(key, value)
  end
end

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/halloween start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :halloween, HalloweenWeb.Endpoint, server: true
end

config :halloween, HalloweenWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

config :halloween, :oidc,
  issuer: System.get_env("OIDC_ISSUER"),
  client_id: System.get_env("OIDC_CLIENT_ID"),
  client_secret: System.get_env("OIDC_CLIENT_SECRET")

# Comma-separated. These guests become hosts when they log in.
config :halloween,
  host_emails:
    System.get_env("HOST_EMAILS", "")
    |> String.split(",", trim: true)
    |> Enum.map(&(&1 |> String.trim() |> String.downcase()))

# The app's language: en (the default) or sv. Starter decks load in it too.
language = System.get_env("PARTY_LANGUAGE", "en")

unless language in ~w(en sv) do
  raise "PARTY_LANGUAGE must be en or sv, not #{inspect(language)}"
end

config :halloween, language: language

if uploads = System.get_env("UPLOADS_PATH") do
  config :halloween, uploads_dir: uploads
end

if config_env() == :dev do
  # Reload browser tabs when matching files change.
  config :halloween, HalloweenWeb.Endpoint,
    live_reload: [
      web_console_logger: true,
      patterns: [
        # Static assets, except user uploads
        ~r"priv/static/(?!uploads/).*\.(js|css|png|jpeg|jpg|gif|svg)$"E,
        # Router, Controllers, LiveViews and LiveComponents
        ~r"lib/halloween_web/router\.ex$"E,
        ~r"lib/halloween_web/(controllers|live|components)/.*\.(ex|heex)$"E
      ]
    ]
end

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /etc/halloween/halloween.db
      """

  config :halloween, Halloween.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :halloween, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :halloween, HalloweenWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://bandit.hexdocs.pm/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :halloween, HalloweenWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://plug.hexdocs.pm/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :halloween, HalloweenWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
