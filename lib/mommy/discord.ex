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
    # Start the table manager

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

  def handle_event({:VOICE_READY, %{guild_id: guild_id} = event, _ws_state}) do
    Logger.warning(event, label: "VOICE_READY")

    {:ok, supervisor, pipeline} =
      Membrane.Pipeline.start(Mommy.Audio, %{
        output_file: "aaa.raw"
      })

    # Register pipeline with TableManager instead of global
    # Mommy.TableManager.register_pipeline(guild_id, supervisor)
    :global.register_name(Mommy.Supervisor, supervisor) |> dbg
    :global.register_name(Mommy.Pipeline, pipeline) |> dbg

    Voice.start_listen_async(guild_id)
  end

  def handle_event({:VOICE_INCOMING_PACKET, rtp_packet, _ws_state}) do
    # You might want to extract this from the packet or store it somewhere
    # guild_id = 475_154_983_910_899_722
    pid = :global.whereis_name(Mommy.Supervisor)
    # Membrane.Pipeline.call(pid, rtp_packet)
    # :global.send(Mommy.Supervisor, {:rtp_packet, rtp_packet})
    # Mommy.TableManager.send_rtp_packet(guild_id, rtp_packet)
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
