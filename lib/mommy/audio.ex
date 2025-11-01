defmodule Mommy.Audio do
  @moduledoc """
  Handles simple audio recording logic.
  """
  use Membrane.Pipeline

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
  def handle_init(ctx , opts) do
    children = [
      source: %Membrane.Discord.Source{
        token: System.get_env("1434169620549599393"),
        guild_id: "475154983910899722",
        channel_id: "476759193244925954"
      },
      decoder: Membrane.Opus.Decoder,
      sink: %Membrane.File.Sink{location: "output.wav"}
    ]
    links= [
      link(:source)
      |> to(:decoder)
      |> to(:sink)
    ]

  {{:ok, spec: %Membrane.ChildrenSpec{children: children, links: links}}, %{}}
  end
end
