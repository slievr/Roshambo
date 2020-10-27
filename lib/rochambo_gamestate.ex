defmodule Rochambo.GameState do
  alias Rochambo.Player

  defstruct player_one: nil, player_two: nil, round_winners: [], state: :need_players

  def get_player_names(%Rochambo.GameState{
        player_one: %Player{name: name1},
        player_two: %Player{name: name2}
      }) do
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

  def get_player_scores(%Rochambo.GameState{
        player_one: %Player{name: name1, score: score1},
        player_two: %Player{name: name2, score: score2}
      }) do
    %{name1 => score1, name2 => score2}
  end

  def get_player_scores(%Rochambo.GameState{
        player_one: nil,
        player_two: %Player{name: name2, score: score2}
      }) do
    %{name2 => score2}
  end

  def get_player_scores(%Rochambo.GameState{
        player_one: %Player{name: name1, score: score1},
        player_two: nil
      }) do
    %{name1 => score1}
  end

  def get_player_scores(%Rochambo.GameState{player_one: nil, player_two: nil}) do
    %{}
  end

  def set_player(game, player, slot) do
    game |> Map.put(slot, player)
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

  def make_player_move(game, player_move, pid) do
    case get_player_by_pid(game, pid) do
      {:ok, player, slot} ->
        moved_player = Player.set_move(player, player_move)

        game =
          game
          |> set_player(moved_player, slot)
          |> determine_outcome()

        {:ok, game}

      {:error, msg} ->
        {:error, msg}
    end
  end

  def add_new_player(game, player = %Player{}) do
    cond do
      game.state == :waiting_for_gambits ->
        {:error, "Already full!"}

      game.player_one == nil ->
        {:ok, %Rochambo.GameState{game | player_one: player}}

      game.player_two == nil ->
        {:ok, %Rochambo.GameState{game | player_two: player}}

      true ->
        {:error, "Already full!"}
    end
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

  def both_players_moved?(%Rochambo.GameState{
        player_one: %Player{move: move1},
        player_two: %Player{move: move2}
      }) do
    move1 != nil && move2 != nil
  end

  def determine_outcome(
        game = %Rochambo.GameState{
          player_one: player1 = %Player{move: move1},
          player_two: player2 = %Player{move: move2}
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
        game
        |> set_outcome({player1, :player_one}, {player2, :player_two})

      {move2, move1} in win_list ->
        game
        |> set_outcome({player2, :player_two}, {player1, :player_one})

      move1 == move2 ->
        set_draw(game, player1, player2)
    end
  end

  def determine_outcome(game = %Rochambo.GameState{}) do
    game
  end

  def get_player_outcome(game, pid) do
    case get_player_by_pid(game, pid) do
      {:ok, %Player{outcome: outcome}, _slot} when not is_nil(outcome) ->
        game = end_round(game, pid)
        {:ok, outcome, game}

      {:ok, %Player{outcome: nil}, _slot} ->
        {:pending, game}

      {:error, msg} ->
        {:error, msg}
    end
  end

  defp set_outcome(game, {winner, slot1}, {loser, slot2}) do
    winner = winner |> Player.set_winner()
    loser = loser |> Player.set_loser()

    game
    |> set_player(winner, slot1)
    |> set_player(loser, slot2)
    |> add_round_winner(winner.identifier)
  end

  defp set_draw(game, player1, player2) do
    game
    |> set_player(player1 |> Player.set_draw(), :player_one)
    |> set_player(player2 |> Player.set_draw(), :player_two)
  end

  defp has_player_one?(%Rochambo.GameState{player_one: player}) do
    !is_nil(player)
  end

  defp has_player_two?(%Rochambo.GameState{player_two: player}) do
    !is_nil(player)
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

  defp end_round(game, pid) do
    case get_player_by_pid(game, pid) do
      {:ok, player, slot} ->
        player = player |> Player.reset_move() |> Player.reset_outcome()

        game
        |> set_player(player, slot)
    end
  end
end
