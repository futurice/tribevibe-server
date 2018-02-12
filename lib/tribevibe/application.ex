defmodule Tribevibe.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(TribevibeWeb.Endpoint, []),
      # Start cache worker
      worker(Cachex, [:officevibe_cache, [
        default_ttl: :timer.seconds(System.get_env("OFFICEVIBE_CACHE_TTL") |> String.to_integer)
      ]])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tribevibe.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TribevibeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
