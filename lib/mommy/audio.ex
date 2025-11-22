defmodule Mommy.Audio do
  @moduledoc """
  Handles simple audio recording logic.
  """
  use Membrane.Pipeline

  alias Membrane.RawAudio

  @impl true
  def handle_init(_ctx, opts) do
    spec =
      child(:source, %Mommy.DiscordRtpSource{receiver_pid: opts[:receiver_pid]})
      |> child(:opus_parser, %Membrane.Opus.Parser{
        generate_best_effort_timestamps?: true
      })
      |> child(:ogg_muxer, Membrane.Ogg.Muxer)
      |> child(:file_sink, %Membrane.File.Sink{location: opts[:output_path]})

    {[spec: spec], %{}}
  end
end
