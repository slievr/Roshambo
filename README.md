# Rochambo

A GenServer that can play Rock, Paper, Scissors.

Once the application starts the `Rochambo.Server` is brought up

## Requirements

local:

- [elixir 1.10.4](https://elixir-lang.org/install.html)
- [erlang > 21](https://www.erlang.org/downloads)

Alternativly [docker](https://docs.docker.com/get-docker/) can be used.

## API

The server `Rochambo.Server` exposes the following functions:

- `status/0` return the current state of the game one of `[:need_players, :waiting_for_gambits]`
- `join/1` enters the game and binds process to player slot
- `play/1` plays the move and returns when round resolves
- `scores/0` returns the score for the game
- `get_players/0` returns the player names


Mutliple game servers can be run twice the following api calls allow for the server name as the first arguemnt

- `status/1` return the current state of the game one of `[:need_players, :waiting_for_gambits]`
- `join/2` enters the game and binds process to player slot
- `play/2` plays the move and returns when round resolves
- `scores/1` returns the score for the game
- `get_players/1` returns the player names

It's also possible to close down a game server using the following

- `kill/1` shuts down the specified game server
- `kill/0` shuts down the default game server

## USAGE

Sample usage:

```elixir
alias Rochambo.Server

def go() do
  Server.status()
  # get game status :need_players signifies a slot

  Server.join(name)
  # ... :joined
  # {:error, reason} when unable

  Server.play(:rock)
  # ... "You won!"

  Server.scores()
  # ... %{"bob" => 1, "michael" => 0}

  Server.players()
  # ... ["bob", "michael"]
end
```

### Docker

A multi stage dockerfile is used for building various images,
the images available are as follows

- Test `docker build --target test -t rocham .`
- Interactive shell `docker build --target iex -t rocham .`
- Porduction release `docker build --target prod -t rocham .`

The image can then be run with `docker run -it rocham`
