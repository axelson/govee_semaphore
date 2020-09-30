defmodule Notes.Server do
  use GenServer
  use EnumType

  require Logger

  alias Govee.CommonCommands
  alias Govee.BLEConnection

  @meeting_in_progress_color 0xFF0000
  @meeting_finished_color 0x0D9106
  @note_color 0x45FFF3

  defenum Mode, generate_ecto_type: false do
    value(Clear, "clear")
    value(MeetingInProgress, "meeting_in_progress")
    value(MeetingFinished, "meeting_finished")
    value(NoteSet, "note_set")
  end

  defmodule State do
    use TypedStruct

    typedstruct(enforce: true) do
      field :note, String.t(), default: nil
      field :mode, Mode.t()
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

  def start_meeting do
    GenServer.call(__MODULE__, :start_meeting)
  end

  def finish_meeting do
    GenServer.call(__MODULE__, :finish_meeting)
  end

  def set_color(color) do
    GenServer.call(__MODULE__, {:set_color, color})
  end

  @impl GenServer
  def init(_opts) do
    state = %State{mode: Mode.Clear}
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
    state = %State{state | note: nil, mode: Mode.Clear}

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

    state = %State{state | note: note, mode: NoteSet}
    {:reply, :ok, state}
  end

  def handle_call(:start_meeting, _, state) do
    flash_color_3_times(@meeting_in_progress_color, Mode.MeetingInProgress)

    state = %State{state | mode: Mode.MeetingInProgress}
    {:reply, :ok, state}
  end

  def handle_call(:finish_meeting, _, state) do
    flash_color_3_times(@meeting_finished_color, Mode.MeetingFinished)

    state = %State{state | mode: Mode.MeetingFinished}
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info({:set_color, color, mode}, state) do
    if state.mode == mode do
      CommonCommands.turn_on() |> run_command()
      CommonCommands.set_color(color) |> run_command()
    end

    {:noreply, state}
  end

  def handle_info({:turn_off, mode}, state) do
    if state.mode == mode do
      CommonCommands.turn_off() |> run_command()
    end

    {:noreply, state}
  end

  def handle_info(event, state) do
    Logger.warn("Unhandled event: #{inspect(event)}")
    {:noreply, state}
  end

  defp flash_color_3_times(color, mode) do
    t = 0

    schedule_color_change(color, t, mode)
    t = t + 1000

    schedule_turn_off(t, mode)
    t = t + 300

    schedule_color_change(color, t, mode)
    t = t + 1000

    schedule_turn_off(t, mode)
    t = t + 300

    schedule_color_change(color, t, mode)
    t = t + 1000

    schedule_turn_off(t, mode)
    t = t + 300

    schedule_color_change(color, t, mode)
  end

  defp schedule_color_change(color, time, mode) do
    Process.send_after(self(), {:set_color, color, mode}, time)
  end

  defp schedule_turn_off(time, mode) do
    Process.send_after(self(), {:turn_off, mode}, time)
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
