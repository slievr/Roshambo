defmodule Rochambo.GameState do
  alias Rochambo.Player

  defstruct player_one: nil, player_two: nil, round_winners: [], state: :need_players

  def get_player_names(%Rochambo.GameState{player_one: %Player{name: name1}, player_two: %Player{name: name2}}) do
    [name1, name2]
  end

  def get_player_names(%Rochambo.GameState{player_one: nil, player_two: %Player{name: name2}}) do
    [name2]
  end

  def get_player_names(%Rochambo.GameState{player_one: %Player{name: name1}, player_two: nil}) do
    [name1]
  end

  def get_player_names(%Rochambo.GameState{player_one: nil, player_two: nil}) do
    []
  end
  def set_player(game, player, slot) do
    Map.put(game, slot, player)
  end

  def add_round_winner(game, pid) do
    %Rochambo.GameState{game | round_winners: game.round_winners ++ [pid]}
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

  def process_winner(game, pid) do
    with {:ok, player, slot} <- get_player_by_pid(game, pid),
         player_scored <- Player.increase_score(player),
         game <- set_player(game, slot, player_scored),
         game <- add_round_winner(game, pid) do
      game
    end
  end

   def resolve_game(game = %Rochambo.GameState{}) do
    with true <- both_players_moved?(game) do
      determine_winner(game)
    else
      false ->
        {:pending, game}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp add_new_player(game, player = %Player{}) do
    cond do
      game.player_one == nil ->
        {:ok, %Rochambo.GameState{game | player_one: player}}

      game.player_two == nil ->
        {:ok, %Rochambo.GameState{game | player_two: player}}

      true ->
        {:error, "Already full!"}
    end
  end

  defp has_player_one?(%Rochambo.GameState{player_one: player}) do
    !is_nil(player)
  end

  defp has_player_two?(%Rochambo.GameState{player_two: player}) do
    !is_nil(player)
  end

  def get_player_by_pid(
        game = %Rochambo.GameState{player_one: player_one, player_two: player_two},
        pid
      ) do

    {game, pid} |> IO.inspect(label: "find pid")

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

  defp determine_winner(
        game = %Rochambo.GameState{
          player_one: %Player{identifier: id1, current_move: move1},
          player_two: %Player{identifier: id2, current_move: move2}
        }
      )
      when not is_nil(move1) and not is_nil(move2) do
    win_list = [
      {:rock, :scissors},
      {:scissors, :paper},
      {:paper, :rock}
    ]

    cond do
      {move1, move2} in win_list ->
        game_state = process_winner(game, id1)
        {:ok, id1, game_state}

      {move2, move1} in win_list ->
        game_state = process_winner(game, id2)
        {:ok, id2, game_state}

      move1 == move2 ->
        {:ok, nil, game}
    end
  end

  def both_players_moved?(game = %Rochambo.GameState{}) do
    game.player_one.current_move != nil && game.player_one.current_move != nil
  end
end
