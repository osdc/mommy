defmodule Mommy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MommyWeb.Telemetry,
      # Start the Ecto repository
      # Mommy.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Mommy.PubSub},
      # Start Finch
      {Finch, name: Mommy.Finch},
      # Start the Endpoint (http/https)
      MommyWeb.Endpoint
      # Start a worker by calling: Mommy.Worker.start_link(arg)
      # {Mommy.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mommy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MommyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
