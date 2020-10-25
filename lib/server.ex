defmodule Rochambo.Server do
  use GenServer

  alias Rochambo.GameState

  # API
  def status() do
    GenServer.call(router(), :get_status)
  end

  def join(_name) do
    {:ok, "not implemented"}
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

  # Casts

  def handle_cast({:join, _player_name}, game = %GameState{}) do
    {:noreply, game}
  end

   def handle_cast({:play, _player_move}, game = %GameState{}) do
    {:noreply, game}
  end

end
