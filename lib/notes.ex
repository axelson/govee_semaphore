defmodule Notes do
  def subscribe do
    :ok = Phoenix.PubSub.subscribe(:notes_pubsub, "notes")
  end

  defdelegate start_link(opts), to: Notes.Server
  defdelegate start_link(opts, genserver_opts), to: Notes.Server
  defdelegate set_note(note), to: Notes.Server
  defdelegate clear_note, to: Notes.Server
  defdelegate get_note, to: Notes.Server
  defdelegate submit_note, to: Notes.Server
  defdelegate start_meeting, to: Notes.Server
  defdelegate finish_meeting, to: Notes.Server
end
