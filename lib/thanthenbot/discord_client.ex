defmodule Thanthenbot.DiscordClient do
  @moduledoc """
  Documentation for `Thanthenbot.DiscordClient`.
  """
  use GenServer

  require Logger

  alias Nostrum.ConsumerGroup
  alias Nostrum.Api
  alias Nostrum.Struct.{Message, Channel, User, Guild}
  alias Thanthenbot.Repo

  defstruct [:serving, :id, report_channel_map: %{}]

  @type t :: %__MODULE__{
          serving: Nx.Serving.t(),
          id: User.id(),
          report_channel_map: %{Guid.id() => Channel.id()}
        }

  @keyword_regex ~r/(^|\W)(than|then)($|\W)/
  @keyword_length 4

  def start_link(opts) do
    {:ok, model_info} =
      Bumblebee.load_model({:hf, "google-bert/bert-base-uncased"})

    {:ok, tokenizer} =
      Bumblebee.load_tokenizer({:hf, "google-bert/bert-base-uncased"})

    serving = Bumblebee.Text.fill_mask(model_info, tokenizer, top_k: 10)
    GenServer.start_link(__MODULE__, serving, opts)
  end

  @impl GenServer
  def init(serving) do
    ConsumerGroup.join(self())
    state = %__MODULE__{serving: serving, id: Api.get_current_user!().id}
    {:ok, state}
  end

  @impl GenServer
  def handle_info({:event, {:GUILD_CREATE, guild, _ws_state}}, state) do
    {:noreply,
     Enum.reduce(guild.channels, state, fn {_channel_id, channel}, state ->
       update_report_channel(channel, state)
     end)}
  end

  @impl GenServer
  def handle_info(
        {:event, {:GUILD_DELETE, {old_guild, _unavailable}, _ws_state}},
        state
      ) do
    {:noreply,
     %__MODULE__{
       state
       | report_channel_map: Map.delete(state.report_channel_map, old_guild.id)
     }}
  end

  @impl GenServer
  def handle_info({:event, {:GUILD_AVAILABLE, guild, _ws_state}}, state) do
    {:noreply,
     Enum.reduce(guild.channels, state, fn {_channel_id, channel}, state ->
       update_report_channel(channel, state)
     end)}
  end

  @impl GenServer
  def handle_info({:event, {:CHANNEL_CREATE, channel, _ws_state}}, state),
    do: {:noreply, update_report_channel(channel, state)}

  @impl GenServer
  def handle_info({:event, {:CHANNEL_UPDATE, channel, _ws_state}}, state),
    do: {:noreply, update_report_channel(channel, state)}

  @impl GenServer
  def handle_info({:event, {:CHANNEL_DELETE, channel, _ws_state}}, state) do
    state =
      if channel.name == "stupid-corner" do
        %__MODULE__{
          state
          | report_channel_map:
              Map.delete(state.report_channel_map, channel.guild_id)
        }
      else
        state
      end

    Logger.debug(inspect(state, pretty: true))

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:event, event}, state) do
    Task.start_link(fn ->
      __MODULE__.handle_event(event, state)
    end)

    {:noreply, state}
  end

  def handle_event(x) do
    Logger.debug("Unhandled event: #{inspect(x)}")
    :noop
  end

  def handle_event(_, _)

  def handle_event(
        {:MESSAGE_CREATE, %Message{author: %User{id: author_id}}, _ws_state},
        %__MODULE__{id: author_id}
      ),
      do: :noop

  def handle_event(
        {:MESSAGE_CREATE,
         %Message{
           content: content,
           channel_id: source_channel_id,
           author: author,
           guild_id: guild_id
         } =
           msg, _ws_state},
        %__MODULE__{serving: serving} = state
      ) do
    Logger.debug("Message content: #{inspect(content)}")

    case process_message(content, serving) do
      nil ->
        :ignore

      corrections ->
        Logger.debug(corrections: corrections)

        log_message(
          content,
          msg.id,
          guild_id,
          source_channel_id,
          author.id,
          author.username
        )

        channel_id =
          Map.get(
            state.report_channel_map,
            guild_id,
            source_channel_id
          )

        correction_messages =
          Enum.map(corrections, fn {offset, correct} ->
            "- [offset: #{offset}] should use \"#{correct}\""
          end)

        full_message =
          Enum.join(
            [
              "# THAN/THEN MISUSE DETECTED!!!!\n" <>
                "- message: #{Message.to_url(msg)}\n" <>
                "- author: #{User.mention(author)}\n" <>
                "Corrections:"
              | correction_messages
            ],
            "\n"
          )

        Api.create_message(channel_id, full_message)
    end
  end

  def handle_event(event, _) do
    Logger.debug("Unhandled event: #{inspect(event)}")
    :noop
  end

  defp update_report_channel(channel, state) do
    if channel.name == "stupid-corner" do
      Logger.debug("Found #stupid-corner: #{inspect(channel, pretty: true)}")

      %__MODULE__{
        state
        | report_channel_map:
            Map.put(state.report_channel_map, channel.guild_id, channel.id)
      }
    else
      state
    end
  end

  def process_message(content, serving) when is_binary(content) do
    occurrence_offsets =
      @keyword_regex
      |> Regex.scan(content, return: :index)
      |> Enum.map(fn
        # idk why I need to do this, but it is required for this to work
        [{0, _length} | _] ->
          0

        [{offset, _length} | _] ->
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

          current_word =
            content
            |> String.slice(middle, @keyword_length)
            |> String.downcase()

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

  # @spec log_message(
  #         String.t(),
  #         Message.id(),
  #         Guild.id(),
  #         Channel.id(),
  #         User.id(),
  #         String.t()
  #       ) :: {:ok, Ecto.Schema.t()} | no_return()
  defp log_message(
         content,
         message_id,
         guild_id,
         channel_id,
         author_id,
         author_name
       ) do
    message = %Thanthenbot.Message{
      content: content,
      author_id: to_string(author_id),
      message_id: to_string(message_id),
      guild_id: to_string(guild_id),
      channel_id: to_string(channel_id),
      author_name: author_name
    }

    case Repo.insert(message) do
      {:ok, struct} -> struct
      {:error, changeset} -> raise changeset
    end
  end
end
