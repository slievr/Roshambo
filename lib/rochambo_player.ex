defmodule Rochambo.Player do
  defstruct name: nil, identifier: nil, score: 0, current_move: nil

  def set_move(player = %Rochambo.Player{}, move) do
    %Rochambo.Player{player | current_move: nil}
  end

  def reset_move(player = %Rochambo.Player{}) do
    %Rochambo.Player{player | current_move: nil}
  end
end
