defmodule Mommy.Summarize do
  @moduledoc """
  Summarizes meeting transcripts using the Gemini API.
  """

  @model "models/gemini-2.5-flash"
  @base "https://generativelanguage.googleapis.com/v1"

  def summarize_text(meeting_text) when is_binary(meeting_text) do
    api_key = System.get_env("GEMINI_API_KEY")

    if is_nil(api_key) or api_key == "" do
      {:error, :missing_api_key}
    else
      url = "#{@base}/#{@model}:generateContent?key=#{api_key}"

      body = %{
        "contents" => [
          %{
            "parts" => [
              %{
                "text" =>
                  "Summarize the following meeting transcript into three sections: Key Discussion Points, Decisions, and Action Items.\n\n" <>
                    meeting_text
              }
            ]
          }
        ]
      }

      headers = [{"content-type", "application/json"}]

      case Req.post(url, json: body, headers: headers) do
        {:ok, %Req.Response{status: 200, body: %{"candidates" => [candidate | _]}}} ->
          summary = get_in(candidate, ["content", "parts", Access.at(0), "text"])
          File.write!("summary.txt", summary)
          {:ok, summary}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end
end
