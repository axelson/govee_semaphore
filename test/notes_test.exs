defmodule NotesTest do
  use ExUnit.Case
  doctest Notes

  test "greets the world" do
    assert Notes.hello() == :world
  end
end
