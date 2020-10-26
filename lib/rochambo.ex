defmodule Rochambo do
  use Application

  alias Rochambo.Server

  def start(_type, _opts) do

    Server.start_link()
  end
end
