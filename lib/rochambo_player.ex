defmodule Rochambo.Player do
  defstruct name: nil, identifier: nil, score: 0, current_move: nil

  def set_move(player = %Rochambo.Player{}, move) do
    %Rochambo.Player{player | current_move: move}
  end

  def reset_move(player = %Rochambo.Player{}) do
    set_move(player, nil)
  end

  def increase_score(player = %Rochambo.Player{}) do
    %Rochambo.Player{player | score: player.score + 1}
  end
end
