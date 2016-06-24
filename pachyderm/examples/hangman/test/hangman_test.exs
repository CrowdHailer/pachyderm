defmodule HangmanTest do
  use ExUnit.Case
  doctest Hangman

  test "A winning Game" do
    {:ok, game} = Hangman.new_game("cat")
    {:ok, state} = Hangman.guess_letter(game, "a")
    IO.inspect(state)
    {:ok, state} = Hangman.guess_letter(game, "c")
    IO.inspect(state)
    {:ok, state} = Hangman.guess_letter(game, "t")
    IO.inspect(state)
  end

  test "A bad Game" do
    {:ok, game} = Hangman.new_game("cat")
    {:error, _reason} = Hangman.guess_letter(game, "aAa")
    {:error, _reason} = Hangman.guess_letter(game, "!")
    {:error, _reason} = Hangman.guess_letter(game, "_")
  end
end
