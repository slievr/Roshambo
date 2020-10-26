defmodule Rochambo.GameState do
  alias Rochambo.Player

  defstruct score: nil, player_one: nil, player_two: nil, round_winners: [], state: :need_players

  def from_map(map) when is_map(map) do
    struct(__MODULE__, map)
  end

  def add_player(game = %Rochambo.GameState{}, player = %Player{}) do
    with :ok <- game_not_full(game),
         :ok <- player_not_in_game(game, player),
         {:ok, updated_game} = add_new_player(game, player) do
      update_gamestate(updated_game)
    else
      {:error, reason} ->
        {:error, reason}

      any ->
        {:error, any}
    end
  end

  defp add_new_player(game, player = %Player{}) do
    cond do
      game.player_one == nil ->
        {:ok, %Rochambo.GameState{game | player_one: player}}

      game.player_two == nil ->
        {:ok, %Rochambo.GameState{game | player_two: player}}

      true ->
        {:error, "no player with pid"}
    end
  end

  def has_player_one?(%Rochambo.GameState{player_one: player}) do
    !is_nil(player)
  end

  def has_player_two?(%Rochambo.GameState{player_two: player}) do
    !is_nil(player)
  end

  def get_player_by_pid(
        game = %Rochambo.GameState{player_one: player_one, player_two: player_two},
        pid
      ) do
    cond do
      has_player_one?(game) && player_one.identifier == pid ->
        {:ok, player_one, :player_one}

      has_player_two?(game) && player_two.identifier == pid ->
        {:ok, player_two, :player_two}

      true ->
        {:error, "no player with pid"}
    end
  end


  def game_not_full(game = %Rochambo.GameState{}) do
    cond do
      game.player_one != nil && game.player_two != nil ->
        {:error, "Already full!"}

      true ->
        :ok
    end
  end

  def player_not_in_game(
        game = %Rochambo.GameState{},
        %Player{identifier: id}
      ) do
    case get_player_by_pid(game, id) do
      {:ok, _, _} ->
        {:error, "Already joined!"}

      {:error, _} ->
        :ok
    end
  end

  defp update_gamestate(game = %Rochambo.GameState{}) do
    cond do
      game.player_one != nil && game.player_two != nil ->
        {:ok, set_gamestate(game, :waiting_for_gambits)}

      true ->
        {:ok, set_gamestate(game, :need_players)}
    end
  end

  defp set_gamestate(game, state) do
    %Rochambo.GameState{game | state: state}
  end

  def determine_winner(game = %Rochambo.GameState{}) do
    determine_winner(game.player_one, game.player_two)
  end

  defp determine_winner(player1 = %Player{}, player2 = %Player{}) do
    win_list = [
      {:rock, :scissors},
      {:scissors, :paper},
      {:paper, :rock}
    ]

    cond do
      {player1.current_move, player2.current_move} in win_list ->
        {:ok, player1.identifier}

      {player2.current_move, player1.current_move} in win_list ->
        {:ok, player2.identifier}

      player2.current_move == player1.current_move ->
        {:ok, nil}
    end
  end

  def both_players_moved?(game = %Rochambo.GameState{}) do
    game.player_one.current_move != nil && game.player_one.current_move != nil
  end
end
