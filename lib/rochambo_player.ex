defmodule Rochambo.Player do
  defstruct name: nil, identifier: nil, score: 0, move: nil, outcome: nil

  def set_move(player = %Rochambo.Player{}, move) do
    %Rochambo.Player{player | move: move}
  end

  def set_outcome(player = %Rochambo.Player{}, outcome) do
    %Rochambo.Player{player | outcome: outcome}
  end

  def reset_move(player = %Rochambo.Player{}) do
    set_move(player, nil)
  end

  def increase_score(player = %Rochambo.Player{}) do
    %Rochambo.Player{player | score: player.score + 1}
  end

  def reset_outcome(player = %Rochambo.Player{}) do
    player
    |> set_outcome(nil)
  end

  def set_winner(player = %Rochambo.Player{}) do
    player
    |> increase_score()
    |> set_outcome("you won!")
  end

  def set_loser(player = %Rochambo.Player{}) do
    player
    |> set_outcome("you lost!")
  end

  def set_draw(player = %Rochambo.Player{}) do
    player
    |> set_outcome("draw!")
  end
end
