defmodule Rochambo.Server do
  use GenServer

  alias Rochambo.{GameState, Player}

  # API
  def status() do
    GenServer.call(router(), :get_status)
  end

  def join(name) do
    GenServer.call(router(), {:join, name})
  end

  def play(_move) do
    {:ok, "not implemented"}
  end

  def scores() do
    {:ok, "not implemented"}
  end

  def get_players() do
    GenServer.call(router(), :get_players)
  end

  defp router() do
    __MODULE__
  end

  # SERVER

  def start_link() do
    GenServer.start_link(router(), [], name: router())
  end

  def init(_opts) do
    {:ok, %GameState{}}
  end

  # Calls

  def handle_call(:get_status, _from, game = %GameState{}) do
    {:reply, game.state, game}
  end

  def handle_call(:get_players, _from, game = %GameState{}) do
    {:reply, game.players, game}
  end

  def handle_call({:join, player_name}, {pid, _ref}, game = %GameState{}) do
    player = %Player{name: player_name, identifier: pid}

    case add_player(player, game) do
      {:ok, new_game_state} ->
        {:reply, :joined, new_game_state}

      {:error, reason} ->
        {:reply, {:error, reason}, game}
    end
  end

  # Casts

  def handle_cast({:play, _player_move}, game = %GameState{}) do
    {:noreply, game}
  end

  defp add_player(player, game) do
    with :ok <- game_not_full(game),
         :ok <- player_not_in_game(player, game) do
      game = %GameState{game | players: game.players ++ [player]}
      update_gamestate(game)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp remove_player(_player, game) do
    update_gamestate(game)
  end

  defp game_not_full(game) do
    cond do
      length(game.players) == 2 ->
        {:error, "Already full!"}

      true ->
        :ok
    end
  end

  defp player_not_in_game(player = %Player{}, game = %GameState{}) do
    in_game =
      game.players
      |> Enum.find_value(false, fn game_player = %Player{} ->
        game_player.identifier == player.identifier
      end)

    case in_game do
      false ->
        :ok

      true ->
        {:error, "Already joined!"}
    end
  end

  defp update_gamestate(game = %GameState{}) do
    case length(game.players) do
        2 ->
          {:ok, %GameState{game | state: :waiting_for_gambits}}
        _ ->
          {:ok, %GameState{game | state: :need_players}}
    end
  end
end
