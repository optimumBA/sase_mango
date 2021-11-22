defmodule SaseMangoTest do
  use ExUnit.Case, async: true
  doctest SaseMango

  test "greets the world" do
    assert SaseMango.hello() == :world
  end
end
