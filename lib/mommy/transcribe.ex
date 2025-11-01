defmodule Mommy.Transcribe do

	@default_model "whisper-1"

	@doc """
	Transcribe a local file and return the transcription text or an error.
	Mommy.Transcribe.transcribe("/home/user/recording.wav")
	"""
	def transcribe(path) do
		transcription_module = OpenaiEx.Audio.Transcription

		if File.exists?(path) == false do
			{:error, {:file_not_found, path}}
		else
			openai_client = OpenaiEx.new(Application.get_env(:openai_ex, :api_key))
			audio_request = transcription_module.new(%{model: @default_model, file: path})
			case transcription_module.create(openai_client, audio_request) do
				{:ok, %{"text" => transcription_text}} -> {:ok, transcription_text}
				{:error, reason} -> {:error, reason}
			end
		end
	end
end
