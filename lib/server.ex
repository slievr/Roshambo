defmodule Rochambo.Server do
  use GenServer

  alias Rochambo.{GameState, Player}

  @registry Rochambo.Registry
  @supervisor Rochambo.GameSupervisor
  @default_game_name "default"

  # API

  def status(game_name) do
    GenServer.call(router(game_name), :get_status)
  end

  def status() do
    GenServer.call(router(), :get_status)
  end

  def join(game_name, name) do
    GenServer.call(router(game_name), {:join, name})
  end

  def join(name) do
    GenServer.call(router(), {:join, name})
  end

  def play(game_name, move) do
    case GenServer.call(router(game_name), {:play, move}) do
      :ok ->
        resolve_round()
    end
  end

  def play(move) do
    case GenServer.call(router(), {:play, move}) do
      :ok ->
        resolve_round()
    end
  end

  def resolve_round(game_name) do
    case GenServer.call(router(game_name), :resolve_round) do
      {:ok, msg} ->
        msg

      :pending ->
        Process.sleep(300)
        resolve_round()

      {:error, msg} ->
        {:error, msg}
    end
  end

  def resolve_round() do
    case GenServer.call(router(), :resolve_round) do
      {:ok, msg} ->
        msg

      :pending ->
        Process.sleep(300)
        resolve_round()

      {:error, msg} ->
        {:error, msg}
    end
  end

  def scores(game_name) do
    GenServer.call(router(game_name), :get_scores)
  end

  def scores() do
    GenServer.call(router(), :get_scores)
  end

  def get_players(game_name) do
    GenServer.call(router(game_name), :get_players)
  end

  def get_players() do
    GenServer.call(router(), :get_players)
  end

  defp router(game_name) do
    {:via, Registry, {@registry, game_name}}
  end

  defp router() do
    {:via, Registry, {@registry, @default_game_name}}
  end

  def debug() do
    GenServer.call(router(), :debug)
  end

  # SERVER

  def start(game_name) do
    opts = [
      game_name: game_name
    ]

    DynamicSupervisor.start_child(@supervisor, {__MODULE__, opts})
  end

  def start() do
    opts = [
      game_name: @default_game_name
    ]

    DynamicSupervisor.start_child(@supervisor, {__MODULE__, opts})
  end

  def start_link(opts) do
    {game_name, opts} = Keyword.pop!(opts, :game_name)
    GenServer.start_link(__MODULE__, opts, name: router(game_name))
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: router())
  end

  def kill(game_name) do
    DynamicSupervisor.terminate_child(@supervisor, Registry.whereis_name({@registry, game_name}))
  end

  def kill() do
    DynamicSupervisor.terminate_child(@supervisor, Registry.whereis_name({@registry, @default_game_name}))
  end

  def init(_opts) do
    {:ok, %GameState{}}
  end

  # Calls

  def handle_call(:get_status, _from, game = %GameState{}) do
    {:reply, game.state, game}
  end

  def handle_call(:get_scores, _from, game = %GameState{}) do
    {:reply, GameState.get_player_scores(game), game}
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

    {pid, player_move} |> IO.inspect(label: "pid")
    moved_player = Player.set_move(player, player_move)

    {:reply, :ok, GameState.set_player(game, moved_player, slot) |> IO.inspect(label: "game")}
  end

  def handle_call(:resolve_round, {pid, _ref}, game = %GameState{}) do
    case GameState.resolve_game(game, pid) do
      {:ok, msg, game_update} ->
        {:reply, {:ok, msg}, game_update}

      {:pending, game_update} ->
        {:reply, :pending, game_update}

      {:error, msg} ->
        {:reply, {:error, msg}, game}
    end
  end
end
