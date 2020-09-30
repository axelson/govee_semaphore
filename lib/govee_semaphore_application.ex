defmodule GoveeSemaphoreApplication do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {GoveeSemaphore.Server, []},
      {Phoenix.PubSub, name: :govee_semaphore_pubsub}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GoveeSemaphore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
