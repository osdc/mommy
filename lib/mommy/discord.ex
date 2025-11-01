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

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    # Run the command, and check for a response message, or default to a checkmark emoji
    message = "_ara ara~ gomenasai_"

    case get_voice_channel_of_interaction(interaction) do
      nil ->
        {:msg, "You must be in a voice channel to summon me"}

      voice_channel_id ->
        Voice.join_channel(interaction.guild_id, voice_channel_id)
    end

    Interaction.create_response(interaction, %{type: 4, data: %{content: message}})
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
