defmodule RochamboTest.Player do
  use ExUnit.Case
  doctest Rochambo
  alias Rochambo.Player

  test "set_move sets move to move" do
    state = %Player{}

    assert %Player{move: :paper} == Player.set_move(state, :paper)
  end

  test "reset_move sets move to nil" do
    state = %Player{move: :paper}

    assert %Player{move: nil} == Player.reset_move(state)
  end

  test "reset_move does not keep state as is" do
    state = %Player{move: :paper}

    assert %Player{move: :paper} != Player.reset_move(state)
  end
end
