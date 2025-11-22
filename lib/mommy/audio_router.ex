defmodule Mommy.AudioRouter do
  use GenServer

  require Logger

  @impl true
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: {:global, "voice::guild::#{opts[:guild_id]}"})
    |> case do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      error -> error
    end
  end

  @impl true
  def init(opts) do
    # Start the pipeline
    {:ok, _supervisor, pipeline} =
      Membrane.Pipeline.start_link(Mommy.Audio, %{
        receiver_pid: self(),
        output_path: "test.ogg"
      })

    {:ok, %{pipeline: pipeline, sink_element: nil, guild_id: opts[:guild_id]}}
  end

  @impl true
  def handle_info({:register_sink, pid}, state) do
    Logger.info("pipeline registered: guild_id: #{state[:guild_id]}")
    {:noreply, %{state | sink_element: pid}}
  end

  @impl true
  def handle_info({:discord_rtp_packet, {{seq, time, ssrc}, opus}}, state) do
    if state[:sink_element] do
      send(state[:sink_element], {:voice_packet, {{seq, time, ssrc}, opus}})
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
