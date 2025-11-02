defmodule Mommy.Audio do
  @moduledoc """
  Handles simple audio recording logic.
  """
  use Membrane.Pipeline
  require Logger

  def record_to_wav(filename, duration_ms) do
    IO.puts("Recording #{filename} for #{duration_ms} ms...")

    sample_rate = 44100
    freq = 440

    total_samples = div(sample_rate * duration_ms, 1000)

    samples =
      for n <- 0..total_samples do
        :math.sin(2 * :math.pi() * freq * n / sample_rate)
      end

    pcm_data =
      samples
      |> Enum.map(fn s ->
        val = round(s * 32767)
        <<val::little-signed-16>>
      end)
      |> IO.iodata_to_binary()

    header = wav_header(byte_size(pcm_data), sample_rate, 1, 16)
    File.write!(filename, [header, pcm_data])

    IO.puts("Saved #{filename}")
    :ok
  end

  defp wav_header(data_size, sample_rate, channels, bits_per_sample) do
    byte_rate = sample_rate * channels * div(bits_per_sample, 8)
    block_align = channels * div(bits_per_sample, 8)

    <<
      "RIFF",
      36 + data_size::little-32,
      "WAVE",
      "fmt ",
      16::little-32,
      1::little-16,
      channels::little-16,
      sample_rate::little-32,
      byte_rate::little-32,
      block_align::little-16,
      bits_per_sample::little-16,
      "data",
      data_size::little-32
    >>
  end

  @impl true
  def handle_init(_ctx, opts) do
    # Since Discord provides already-depayloaded Opus frames,
    # we can skip the RTP parsing and go directly to Opus decoding
    spec =
      [
        child(:discord_source, Mommy.DiscordRtpSource)
        |> child(:decoder, Membrane.Opus.Decoder)
        |> child(:file_sink, %Membrane.File.Sink{location: opts.output_file})
      ]

    {[spec: spec], %{output_file: opts.output_file, ssrc: nil}}
  end

  @impl true
  def handle_child_notification(
        {:new_rtp_stream, ssrc, _pt, _extensions},
        :rtp_source,
        _ctx,
        state
      ) do
    IO.puts("New RTP stream detected with SSRC: #{ssrc}")

    spec =
      [
        get_child(:rtp_source)
        |> via_out(Pad.ref(:output, ssrc))
        |> child(:depayloader, Membrane.RTP.Opus.Depayloader)
        |> child(:decoder, Membrane.Opus.Decoder)
        |> child(:audio_player, Membrane.PortAudio.Sink)
      ]

    # |> child(:mp3_encoder, Membrane.MP3.Lame.Encoder)
    # |> child(:sink, %Membrane.File.Sink{
    #   location: opts.output_file
    # })
    {[spec: spec], %{state | ssrc: ssrc}}
  end

  @impl true
  def handle_child_notification(notification, element, _ctx, state) do
    IO.inspect(notification, label: "Notification from #{element}")
    {[], state}
  end

  @impl true
  def handle_info({:packet, packet}, _ctx, state) when is_binary(packet) do
    if state.source_pid do
      # Forward packet to CustomSource
      send(state.source_pid, {:packet, packet})
    else
      IO.warn("CustomSource not ready yet, packet dropped")
    end

    {[], state}
  end

  @impl true
  def handle_info(x, _ctx, state) do
    Logger.debug(x)
    {[], state}
  end
end
