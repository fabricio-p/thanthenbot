defmodule Thanthenbot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ThanthenbotWeb.Telemetry,
      Thanthenbot.Repo,
      {DNSCluster,
       query: Application.get_env(:thanthenbot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Thanthenbot.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Thanthenbot.Finch},
      # Start a worker by calling: Thanthenbot.DiscordClient.start_link(arg)
      Thanthenbot.DiscordClient,
      # Start to serve requests, typically the last entry
      ThanthenbotWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Thanthenbot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ThanthenbotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
