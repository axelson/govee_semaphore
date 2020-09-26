defmodule Notes.Server do
  use GenServer

  alias Govee.CommonCommands
  alias Govee.BLEConnection

  # @meeting_in_progress_color 0xFF0000
  # @meeting_finished_color 0x0D9106
  @note_color 0x45FFF3

  defmodule State do
    use TypedStruct

    typedstruct(enforce: true) do
      field :note, String.t(), default: nil
    end
  end

  def start_link(opts, genserver_opts \\ []) do
    genserver_opts = Keyword.put_new(genserver_opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, genserver_opts)
  end

  def set_note(note) do
    GenServer.call(__MODULE__, {:set_note, note})
  end

  def clear_note do
    GenServer.call(__MODULE__, :clear_note)
  end

  def get_note do
    GenServer.call(__MODULE__, :get_note)
  end

  def submit_note do
    GenServer.call(__MODULE__, :submit_note)
  end

  @impl GenServer
  def init(_opts) do
    state = %State{}
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:set_note, note}, _from, state) do
    state = %State{state | note: note}
    {:reply, :ok, state}
  end

  def handle_call(:clear_note, _from, state) do
    CommonCommands.turn_off() |> run_command()
    Phoenix.PubSub.broadcast!(:notes_pubsub, "notes", {:notes, :submit_note, nil})
    state = %State{state | note: nil}

    {:reply, :ok, state}
  end

  def handle_call(:get_note, _from, state) do
    {:reply, state.note, state}
  end

  def handle_call(:submit_note, _from, state) do
    CommonCommands.turn_on() |> run_command()
    CommonCommands.set_color(@note_color) |> run_command()
    note = state.note || :empty
    Phoenix.PubSub.broadcast!(:notes_pubsub, "notes", {:notes, :submit_note, note})

    state = %State{state | note: note}
    {:reply, :ok, state}
  end

  defp run_command(command) do
    for_each_device(fn device ->
      CommonCommands.send_command(command, device.att_client)
    end)
  end

  defp for_each_device(fun) when is_function(fun, 1) do
    Enum.each(BLEConnection.connected_devices(Server), fun)
  end
end
