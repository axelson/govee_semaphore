defmodule GoveeSemaphore do
  def subscribe do
    :ok = Phoenix.PubSub.subscribe(:govee_semaphore_pubsub, "govee_semaphore")
  end

  defdelegate start_link(opts), to: GoveeSemaphore.Server
  defdelegate start_link(opts, genserver_opts), to: GoveeSemaphore.Server
  defdelegate set_note(note), to: GoveeSemaphore.Server
  defdelegate clear_note, to: GoveeSemaphore.Server
  defdelegate get_note, to: GoveeSemaphore.Server
  defdelegate submit_note, to: GoveeSemaphore.Server
  defdelegate start_meeting, to: GoveeSemaphore.Server
  defdelegate finish_meeting, to: GoveeSemaphore.Server
end
