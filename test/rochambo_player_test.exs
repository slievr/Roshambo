defmodule RochamboTest.Player do
  use ExUnit.Case
  doctest Rochambo
  alias Rochambo.Player

  test "set_move sets current_move to move" do
    state = %Player{}

    assert %Player{current_move: :paper} == Player.set_move(state, :paper)
  end

  test "reset_move sets current_move to nil" do
    state = %Player{current_move: :paper}

    assert %Player{current_move: nil} == Player.reset_move(state)
  end

  test "reset_move does not keep state as is" do
    state = %Player{current_move: :paper}

    assert %Player{current_move: :paper} != Player.reset_move(state)
  end
end
