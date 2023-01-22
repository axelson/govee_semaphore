defmodule GoveeSemaphore.Server do
  use GenServer
  use EnumType

  require Logger

  alias Govee.Command

  @meeting_in_progress_color 0xFF0000
  @meeting_finished_color 0x0D9106
  @default_brightness 132

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

  def start_meeting(conn) do
    GenServer.call(__MODULE__, {:start_meeting, conn})
  end

  def finish_meeting(conn) do
    GenServer.call(__MODULE__, {:finish_meeting, conn})
  end

  def set_color(conn, color) do
    GenServer.call(__MODULE__, {:set_color, conn, color})
  end

  @impl GenServer
  def init(_opts) do
    state = %State{mode: Mode.Clear}
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:start_meeting, conn}, _, state) do
    flash_color_3_times(conn, @meeting_in_progress_color, Mode.MeetingInProgress)

    state = %State{state | mode: Mode.MeetingInProgress}
    {:reply, :ok, state}
  end

  def handle_call({:finish_meeting, conn}, _, state) do
    time_delay = flash_color_3_times(conn, @meeting_finished_color, Mode.MeetingFinished)
    schedule_fade_out(conn, time_delay + 5000)

    state = %State{state | mode: Mode.MeetingFinished}
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info({:set_color, conn, color, mode}, state) do
    if state.mode == mode do
      Command.turn_on() |> execute_command(conn)
      Command.set_color(color) |> execute_command(conn)
    end

    {:noreply, state}
  end

  def handle_info({:turn_off, conn, mode}, state) do
    if state.mode == mode do
      Command.turn_off() |> execute_command(conn)
    end

    {:noreply, state}
  end

  def handle_info({:fade_out, conn, brightness}, state) do
    if state.mode == Mode.MeetingFinished do
      Command.set_brightness(brightness) |> execute_command(conn)
      step_delay = 15

      cond do
        brightness == 0 -> Command.turn_off() |> execute_command(conn)
        brightness > 1 -> schedule_fade_out(conn, step_delay, brightness - 1)
        brightness <= 1 -> schedule_fade_out(conn, step_delay, 0)
      end
    end

    {:noreply, state}
  end

  def handle_info(event, state) do
    Logger.warn("Unhandled event: #{inspect(event)}")
    {:noreply, state}
  end

  defp flash_color_3_times(conn, color, mode) do
    t = 0

    Command.set_brightness(@default_brightness) |> execute_command(conn)
    schedule_color_change(conn, color, t, mode)
    t = t + 1000

    schedule_turn_off(conn, t, mode)
    t = t + 300

    schedule_color_change(conn, color, t, mode)
    t = t + 1000

    schedule_turn_off(conn, t, mode)
    t = t + 300

    schedule_color_change(conn, color, t, mode)
    t = t + 1000

    schedule_turn_off(conn, t, mode)
    t = t + 300

    schedule_color_change(conn, color, t, mode)
    t
  end

  defp schedule_color_change(conn, color, time, mode) do
    Process.send_after(self(), {:set_color, conn, color, mode}, time)
  end

  defp schedule_turn_off(conn, time, mode) do
    Process.send_after(self(), {:turn_off, conn, mode}, time)
  end

  defp schedule_fade_out(conn, time, brightness \\ @default_brightness) do
    Process.send_after(self(), {:fade_out, conn, brightness}, time)
  end

  defp execute_command(command, conn) do
    GoveeScenic.execute_command(conn, command)
  end
end
