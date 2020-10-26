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

  def play(move) do
    GenServer.cast(router(), {:play, move, System.get_pid()})

    play()
  end

  def play() do
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

  def debug() do
    GenServer.call(router(), :debug)
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
    {:reply, [game.player_one, game.player_two], game}
  end

  def handle_call({:join, player_name}, {pid, _ref}, game = %GameState{}) do
    player = %Player{name: player_name, identifier: pid}

    case GameState.add_player(game, player) do
      {:ok, new_game_state} ->
        {:reply, :joined, new_game_state}

      {:error, reason} ->
        {:reply, {:error, reason}, game}
    end
  end

  def handle_call(:debug, _from, game = %GameState{}) do
    {:reply, game, game}
  end

  # Casts

  def handle_cast({:play, player_move, pid}, game = %GameState{}) do
    {:ok, player, slot} = GameState.get_player_by_pid(game, pid)
    moved_player = Player.set_move(player, player_move)
    updated_game_state = Map.put(game, slot, moved_player)

    {:noreply, GameState.from_map(updated_game_state)}
  end

  defp remove_player(_player, game) do
    GameState.update_gamestate(game)
  end

  defp resolve_game(game = %GameState{}) do
    with true <- GameState.both_players_moved?(game),
         {:ok, pid} <- GameState.determine_winner(game) do
      %GameState{game | round_winners: game.round_winners ++ [{pid}]}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp reset_players_moves(game = %GameState{}) do
    %GameState{
      game
      | player_one: Player.reset_move(game.player_one),
        player_two: Player.reset_move(game.player_two)
    }
  end
end
