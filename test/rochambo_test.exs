defmodule RochamboTest do
  use ExUnit.Case
  doctest Rochambo
  alias Rochambo.Server

  test "server" do
    name = "bob"
    Server.start_link()

    # Initial status - need players
    assert Server.status() == :need_players

    # Join the server
    assert Server.join(name) == :joined

    # Can't join the server again!
    assert Server.join(name) == {:error, "Already joined!"}

    # Start other player
    Task.start_link(&other_player/0)

    # Ensure other process has had the opportunity to join
    Process.sleep(100)

    assert Server.status() == :waiting_for_gambits
    assert Enum.sort(Server.get_players()) == ["bob", "michael"]

    # Play a rock against Michael's scissors
    assert Server.play(:rock) =~ "you won!"
    assert Server.scores() == %{"bob" => 1, "michael" => 0}

    # Play paper against Michael's paper
    assert Server.play(:paper) =~ "draw"

    # Score is unchanged
    assert Server.scores() == %{"bob" => 1, "michael" => 0}

    # A third user can't join
    Task.async(&third_wheel/0)
    |> Task.await()
  end

  def other_player() do
    name = "michael"
    Server.join(name)
    # Ensure other process has had the opportunity to join
    Process.sleep(100)

    assert Server.play(:scissors) =~ "you lost!"
    assert Server.scores() == %{"bob" => 1, "michael" => 0}

    Process.sleep(100)

    assert Server.play(:paper) =~ "draw"
  end

  def third_wheel() do
    assert Server.join("henry") == {:error, "Already full!"}
  end

  test "multiple servers" do
    assert {:ok, pid1} = Server.start("test2")
    assert {:ok, pid2} = Server.start("test3")

    assert pid1 != pid2

    Server.join("test2", "server1player")

    Server.join("test3", "server2player")

    assert Server.get_players("test2") != Server.get_players("test3")

    assert length(Server.get_players("test2")) == 1
    assert length(Server.get_players("test3")) == 1

    assert {:error, _} = Server.start("test2")
    assert {:error, _} = Server.start("test3")

    Server.kill("test3")
    assert {:ok, _pid} = Server.start("test3")
    assert length(Server.get_players("test3")) == 0

  end
end
