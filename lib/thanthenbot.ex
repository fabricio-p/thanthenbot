defmodule Thanthenbot do
  @moduledoc """
  Documentation for `Thanthenbot`.
  """
  # Nostrum.Consumer
  use GenServer

  require Logger

  alias Nostrum.ConsumerGroup
  alias Nostrum.Api
  alias Nostrum.Struct.{Message, Channel, User, Guild}
  alias Nostrum.Cache.{Me, GuildCache}

  @keyword_regex ~r/(^|\W)(than|then)($|\W)/
  @keyword_length 4

  def start_link(opts) do
    {:ok, model_info} =
      Bumblebee.load_model({:hf, "google-bert/bert-base-uncased"})

    {:ok, tokenizer} =
      Bumblebee.load_tokenizer({:hf, "google-bert/bert-base-uncased"})

    serving = Bumblebee.Text.fill_mask(model_info, tokenizer)
    GenServer.start_link(__MODULE__, serving, opts)
  end

  @impl GenServer
  def init(serving) do
    ConsumerGroup.join(self())
    {:ok, serving}
  end

  @impl GenServer
  def handle_info({:event, event}, serving) do
    Task.start_link(fn ->
      __MODULE__.handle_event(event, serving)
    end)

    {:noreply, serving}
  end

  def handle_event(_), do: :noop

  def handle_event(_, _)

  def handle_event(
        {:MESSAGE_CREATE,
         %Message{
           content: content,
           channel_id: source_channel_id,
           author: author,
           guild_id: guild_id
         } =
           msg, _ws_state},
        serving
      ) do
    Logger.debug("Message content: #{inspect(content)}")

    unless author.id == Me.get().id do
      case process_message(content, serving) do
        nil ->
          :ignore

        corrections ->
          Logger.debug(corrections: corrections)

          %Guild{channels: channels} = GuildCache.get!(guild_id)

          {channel_id, _} =
            channels
            |> Map.to_list()
            |> Enum.find(
              {source_channel_id, nil},
              fn {_id, %Channel{name: name}} ->
                name == "stupid-corner"
              end
            )

          correction_messages =
            Enum.map(corrections, fn {offset, correct} ->
              "  at #{offset}, should use #{correct}"
            end)

          full_message =
            Enum.join(
              [
                "than/then misuse detected at message " <>
                  "[#{Message.to_url(msg)}], channel " <>
                  "[#{Channel.mention(channels[source_channel_id])}] from " <>
                  "[#{User.mention(author)}]. Corrections are as follows:"
                | correction_messages
              ],
              "\n"
            )

          Api.create_message(channel_id, full_message)
      end
    end
  end

  def handle_event(_, _), do: :noop

  def process_message(content, serving) when is_binary(content) do
    occurrence_offsets =
      @keyword_regex
      |> Regex.scan(content, return: :index)
      |> Enum.map(fn [{offset, _length} | _] ->
        # idk why + 1, it is required for this to work
        offset + 1
      end)

    if length(occurrence_offsets) == 0 do
      nil
    else
      start_offsets = [0 | occurrence_offsets]
      middle_offsets = occurrence_offsets
      [_ | end_offsets] = occurrence_offsets ++ [String.length(content) - 1]

      sections = Enum.zip([start_offsets, middle_offsets, end_offsets])

      corrections =
        for {front, middle, back} <- sections do
          string =
            Enum.join([
              String.slice(content, front, middle - front),
              "[MASK]",
              String.slice(content, middle + @keyword_length, back - middle)
            ])

          {than_score, then_score} =
            serving
            |> Nx.Serving.run(string)
            |> process_inference()

          current_word = String.slice(content, middle, @keyword_length)

          case current_word do
            "then" when than_score > then_score -> {middle, "than"}
            "than" when then_score > than_score -> {middle, "then"}
            _ -> nil
          end
        end

      case Enum.filter(corrections, &(&1 != nil)) do
        [] -> nil
        corrections -> corrections
      end
    end
  end

  defp process_inference(%{predictions: predictions}) do
    Enum.reduce(predictions, {0, 0}, fn %{score: score, token: token},
                                        {than_score, then_score} ->
      case token do
        "than" -> {score, then_score}
        "then" -> {than_score, score}
        _ -> {than_score, then_score}
      end
    end)
  end
end
