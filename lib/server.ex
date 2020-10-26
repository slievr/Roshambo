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
    GenServer.call(router(), {:play, move})

    play()
  end

  def play() do
    case GenServer.call(router(), :resolve_round) do
      {:ok, msg} ->
        msg

      :pending ->
        Process.sleep(300)
        play()

      {:error, msg} ->
        {:error, msg}
    end
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
    {:reply, GameState.get_player_names(game), game}
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

   def handle_call({:play, player_move}, {pid, _ref}, game = %GameState{}) do
    {:ok, player, slot} = GameState.get_player_by_pid(game, pid)
    moved_player = Player.set_move(player, player_move)

    {:reply, :ok, GameState.set_player(game, moved_player, slot)}
  end

  def handle_call(:resolve_round, _from, game = %GameState{}) do
    case GameState.resolve_game(game) do
      {:ok, msg, game_update} ->
        {:reply, msg, game_update}

      {:pending, game_update} ->
        {:reply, :pending, game_update}

      {:error, msg} ->
        {:reply, {:error, msg}, game}
    end
  end
end
