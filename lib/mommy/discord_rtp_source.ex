defmodule Mommy.DiscordRtpSource do
  @moduledoc """
  A Membrane source element that receives Opus audio frames from Discord
  and outputs them for decoding.
  """
  use Membrane.Source
  require Logger
  alias Membrane.{Buffer, RemoteStream, Opus}

  def_output_pad :output,
    accepted_format: %RemoteStream{type: :packetized, content_format: Opus},
    flow_control: :push

  @impl true
  def handle_init(_ctx, _opts) do
    :global.register_name(__MODULE__, self())
    {[], %{playing?: false, buffer: []}}
  end

  @impl true
  def handle_playing(_ctx, state) do
    stream_format = %RemoteStream{type: :packetized, content_format: Opus}

    # Send any buffered packets after the stream format
    buffer_actions = Enum.map(state.buffer, fn buffer -> {:buffer, {:output, buffer}} end)

    actions = [stream_format: {:output, stream_format}] ++ buffer_actions

    {actions, %{state | playing?: true, buffer: []}}
  end

  @impl true
  def handle_info({:discord_rtp_packet, {{sequence_number, _timestamp, ssrc}, payload}}, _ctx, state) do
    unless payload == <<248, 255, 254>> do       #this is a silence frame
      Logger.debug("Processing Opus frame: seq=#{sequence_number}, ssrc=#{ssrc}, size=#{byte_size(payload)}")
      buffer = %Buffer{payload: payload}

      if state.playing? do
        {[buffer: {:output, buffer}], state}
      else
        # Buffer until we start playing i.e. membrane pipeline is ready
        {[], %{state | buffer: [buffer | state.buffer]}}
      end
    else
      {[], state}
    end
  end

  @impl true
  def handle_info(msg, _ctx, state) do
    Logger.warning("Unexpected message: #{inspect(msg, limit: 50)}")
    {[], state}
  end
end
