defmodule Mommy.DiscordRtpSource do
  @moduledoc """
  A Membrane source element that receives Opus audio frames from Discord
  and outputs them for decoding.
  """
  use Membrane.Source

  require Logger

  alias Membrane.{Buffer, RemoteStream}
  alias Membrane.Opus

  # def_output_pad(:output,
  #   accepted_format: %RemoteStream{type: :packetized, content_format: Opus},
  #   flow_control: :push
  # )

  def_output_pad(:output,
    accepted_format: %Opus{self_delimiting?: false, channels: 1},
    flow_control: :push
  )

  def_options(
    receiver_pid: [spec: pid(), description: "PID to register with for receiving packets"]
  )

  @impl true
  def handle_init(_ctx, opts) do
    # Logger.info("pipeline init: #{opts.receiver_pid} | #{self()}")
    {[], %{receiver_pid: opts.receiver_pid, pts: 0, queue: :queue.new()}}
  end

  @impl true
  def handle_playing(_ctx, state) do
    # Register this element to receive voice packets
    # Logger.info("playing startomg, registering: #{state.receiver_pid} | #{self()}")
    send(state.receiver_pid, {:register_sink, self()})
    # stream_format = %RemoteStream{type: :packetized, content_format: Opus}
    stream_format = %Opus{self_delimiting?: false, channels: 1}
    {[stream_format: {:output, stream_format}], state}
  end

  @impl true
  def handle_info({:voice_packet, {metadata, opus_data}}, _ctx, state) do
    frame_duration = Membrane.Time.milliseconds(20)

    buffer = %Buffer{
      payload: opus_data,
      metadata: %{rtp: metadata}
      # pts: state.pts
    }

    new_pts = state.pts + frame_duration

    {[buffer: {:output, buffer}], %{state | pts: new_pts}}
  end
end
