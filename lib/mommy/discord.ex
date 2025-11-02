defmodule Mommy.Discord do
  @behaviour Nostrum.Consumer

  alias Nostrum.Api.{
    ApplicationCommand,
    Interaction
  }

  alias Nostrum.Cache.{
    GuildCache
  }

  alias Nostrum.Voice

  require Logger

  def handle_event({:READY, event, _ws_state}) do
    :ets.new(:membrane_pipelines, [:named_table, :set, :public]) |> dbg

    event.guilds
    |> Enum.each(fn guild ->
      ApplicationCommand.create_guild_command(
        guild.id,
        %{
          name: "mom",
          description: "connect to voice channel",
          options: []
        }
      )
    end)
  end

  def handle_event({:INTERACTION_CREATE, %{guild_id: guild_id} = interaction, _ws_state}) do
    # Run the command, and check for a response message, or default to a checkmark emoji
    message = "_ara ara~ gomenasai_"

    case get_voice_channel_of_interaction(interaction) do
      nil ->
        {:msg, "You must be in a voice channel to summon me"}

      voice_channel_id ->
        Voice.join_channel(guild_id, voice_channel_id)
    end

    Interaction.create_response(interaction, %{type: 4, data: %{content: message}})
  end

  def handle_event({:VOICE_READY, event, _ws_state}) do
    Logger.warning(event, label: "VOICE_READY")

    {:ok, _supervisor, pipeline} =
      Membrane.Pipeline.start_link(Mommy.Audio, %{
        output_file: "aaa.raw"
      })

    # :ets.insert(:membrane_pipelines, {"foo", pipeline})
    :global.register_name(:membrane_pipe, pipeline)

    Voice.start_listen_async(475_154_983_910_899_722)
  end

  def handle_event({:VOICE_INCOMING_PACKET, rtp_packet, _ws_state}) do
    # Logger.info(rtp_packet)
    # pipeline = :ets.lookup(:membrane_pipelines, "foo")
    # Membrane.Core.call(pipeline, rtp_packet)

    :global.send(:membrane_pipe, {:rtp_packet, rtp_packet})
  end

  def handle_event(_), do: :noop

  # HELPER FUNCTIONS

  def get_voice_channel_of_interaction(%{guild_id: guild_id, user: %{id: user_id}} = _interaction) do
    guild_id
    |> GuildCache.get!()
    |> Map.get(:voice_states)
    |> Enum.find(%{}, fn v -> v.user_id == user_id end)
    |> Map.get(:channel_id)
  end

  # def pipeline do
  #   fetch_packets()
  #   |> Mommy.Audio.process() # depends on the opus_stream
  #   |> Mommy.Transcribe.process() # independent
  #   |> Mommy.Summarize.summarize() # independent
  #   |> send_to_channel()
  # end
end
