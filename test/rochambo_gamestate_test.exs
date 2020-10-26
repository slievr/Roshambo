defmodule RochamboTest.GameState do
  use ExUnit.Case
  doctest Rochambo
  alias Rochambo.{GameState, Player}

  test "game not full when empty" do
    state = %GameState{}

    assert GameState.game_not_full(state) == :ok
  end

  test "game full when filled" do
    state = %GameState{
      player_one: %Player{
        name: "test",
        identifier: "1",
        current_move: :paper,
        score: 0
      },
      player_two: %Player{
        name: "test2",
        identifier: "2",
        current_move: :rock,
        score: 0
      }
    }

    assert {:error, _} = GameState.game_not_full(state)
  end

  test "winner" do
    state = %GameState{
      player_one: %Player{
        name: "test",
        identifier: "1",
        current_move: :paper,
        score: 0
      },
      player_two: %Player{
        name: "test2",
        identifier: "2",
        current_move: :rock,
        score: 0
      },
      state: :waiting_for_gambits
    }

    assert {:ok, "1", _game} = GameState.resolve_game(state)
  end

  test "set_player sets player at slot to player" do
    state = %GameState{}

    player = %Player{
      name: "test2",
      identifier: "2",
      current_move: :rock,
      score: 0
    }

    assert %GameState{player_one: player} = GameState.set_player(state, player, :player_one)
    assert %GameState{player_one: player} != GameState.set_player(state, player, :player_two)

    assert %GameState{player_two: player} = GameState.set_player(state, player, :player_two)
    assert %GameState{player_two: player} != GameState.set_player(state, player, :player_one)
  end

  test "add player" do
    state = %GameState{}

    player1 = %Player{
      name: "test1",
      identifier: "1"
    }

    player2 = %Player{
      name: "test2",
      identifier: "2"
    }

    {:ok, game} = GameState.add_player(state, player1)

    assert %GameState{player_one: player1, player_two: nil} == game

    {:ok, game} = GameState.add_player(game, player2)

    assert %GameState{player_one: player1, player_two: player2, state: :waiting_for_gambits} ==
             game
  end

  test "get player by pid" do
    state = %GameState{
      player_one: %Player{
        name: "test",
        identifier: "1",
        current_move: :paper,
        score: 0
      },
      player_two: %Player{
        name: "test2",
        identifier: "2",
        current_move: :rock,
        score: 0
      },
      state: :waiting_for_gambits
    }

    assert {:ok, %Player{name: "test"}, :player_one} = GameState.get_player_by_pid(state, "1")
  end

    test "get player names when empty" do
    state = %GameState{

    }

     assert [] = GameState.get_player_names(state)
  end

  test "get player names when player_one entry" do
    state = %GameState{
      player_one: %Player{
        name: "test",
        identifier: "1",
        current_move: :paper,
        score: 0
      },
    }

    assert ["test"] = GameState.get_player_names(state)
  end

  test "get player names when player_two entry" do
    state = %GameState{
      player_two: %Player{
        name: "test2",
        identifier: "1",
        current_move: :paper,
        score: 0
      },
    }

    assert ["test2"] = GameState.get_player_names(state)
  end

    test "get player names when full" do
     state = %GameState{
      player_one: %Player{
        name: "test",
        identifier: "1",
        current_move: :paper,
        score: 0
      },
      player_two: %Player{
        name: "test2",
        identifier: "2",
        current_move: :rock,
        score: 0
      },
      state: :waiting_for_gambits
    }

     assert ["test", "test2"] = GameState.get_player_names(state)
  end
end
