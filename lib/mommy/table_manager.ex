defmodule Mommy.TableManager do
  use GenServer

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def register_pipeline(guild_id, pipeline_pid) do
    GenServer.call(__MODULE__, {:register_pipeline, guild_id, pipeline_pid})
  end

  def send_rtp_packet(guild_id, rtp_packet) do
    GenServer.cast(__MODULE__, {:rtp_packet, guild_id, rtp_packet})
  end

  def get_pipeline(guild_id) do
    GenServer.call(__MODULE__, {:get_pipeline, guild_id})
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    # Create ETS table to store guild_id -> pipeline_pid mappings
    :ets.new(:membrane_pipelines, [:named_table, :set, :public])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:register_pipeline, guild_id, pipeline_pid}, _from, state) do
    :ets.insert(:membrane_pipelines, {guild_id, pipeline_pid})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:get_pipeline, guild_id}, _from, state) do
    case :ets.lookup(:membrane_pipelines, guild_id) do
      [{^guild_id, pipeline_pid}] -> {:reply, {:ok, pipeline_pid}, state}
      [] -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_cast({:rtp_packet, guild_id, rtp_packet}, state) do
    case :ets.lookup(:membrane_pipelines, guild_id) do
      [{^guild_id, pipeline_pid}] ->
        # Send RTP packet to the pipeline
        # send(pipeline_pid,{:rtp_packet, rtp_packet})
        GenServer.cast(pipeline_pid, {:rtp_packet, rtp_packet})

      [] ->
        require Logger
        Logger.warning("No pipeline found for guild_id: #{guild_id}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # Clean up ETS table when a pipeline process dies
    :ets.match_delete(:membrane_pipelines, {:_, pid})
    {:noreply, state}
  end
end
