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

  def handle_call({:join, player_name}, from, game = %GameState{}) do
    player = %Player{name: player_name, identifier: from}

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
    case can_join?(game) do
      true ->
        {:ok, %GameState{game | players: game.players ++ [player]}}
      false ->
        {:error, "Already full!"}
    end
  end

  defp can_join?(game) do
    cond do
      length(game.players) == 2 ->
        false
      true ->
        true
    end
  end

end
