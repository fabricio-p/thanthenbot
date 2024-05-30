# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :thanthenbot,
  ecto_repos: [Thanthenbot.Repo],
  generators: [timestamp_type: :utc_datetime]

config :nostrum,
  # System.get_env("DISCORD_TOKEN"),
  token: "",
  gateway_intents: [
    :guilds,
    :guild_messages,
    :message_content
  ]

if File.exists?("config/secret.exs"), do: import_config("secret.exs")

config :logger, :console, metadata: [:shard, :guild, :channel]

config :nx, default_backend: EXLA.Backend

# Configures the endpoint
config :thanthenbot, ThanthenbotWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ThanthenbotWeb.ErrorHTML, json: ThanthenbotWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Thanthenbot.PubSub,
  live_view: [signing_salt: "zrEzvMKb"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :thanthenbot, Thanthenbot.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  thanthenbot: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  thanthenbot: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
