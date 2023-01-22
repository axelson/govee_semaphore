defmodule GoveeSemaphore do
  def subscribe do
    :ok = Phoenix.PubSub.subscribe(:govee_semaphore_pubsub, "govee_semaphore")
  end

  defdelegate start_link(opts), to: GoveeSemaphore.Server
  defdelegate start_link(opts, genserver_opts), to: GoveeSemaphore.Server
  defdelegate start_meeting(conn), to: GoveeSemaphore.Server
  defdelegate finish_meeting(conn), to: GoveeSemaphore.Server
end
