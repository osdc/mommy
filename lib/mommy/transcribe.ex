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

			# Read the file as binary data
			case File.read(path) do
				{:ok, file_content} ->
					# Create request with binary content and filename
					audio_request = transcription_module.new(%{
						model: @default_model,
						file: {Path.basename(path), file_content}
					})

					case transcription_module.create(openai_client, audio_request) do
						{:ok, %{"text" => transcription_text}} -> {:ok, transcription_text}
						{:error, reason} -> {:error, reason}
					end

				{:error, reason} -> {:error, {:file_read_error, reason}}
			end
		end
	end
end
