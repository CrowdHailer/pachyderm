defmodule Hangman do
  defmodule Command do
    defmodule Guess, do: defstruct [letter: nil]
  end
  defmodule State.Playing do
    defstruct [id: nil, word: nil, correct: MapSet.new, incorrect: MapSet.new]
  end
  defimpl Pachyderm.Protocol, for: State.Playing do
    def instruct(%{word: word, correct: correct, incorrect: incorrect, id: id}, %Command.Guess{letter: letter}) do
      previous? = MapSet.member?(correct, letter)
      correct? = Enum.member?(String.split(word, ""), letter)
      case {previous?, correct?} do
        {true, _} ->
          {:ok, []}
        {false, false} ->
          {:ok, [
            Pachyderm.Adjustment.set(id, :incorrect, letter)
          ]}
        {false, true} ->
          {:ok, [
            Pachyderm.Adjustment.set(id, :correct, letter)
          ]}
      end
    end
  end
  alias __MODULE__.State.{Playing, Won, Lost}

  import Pachyderm.{Adjustment, Ledger, Entity}
  def creation(word, id) do
    {:ok, [
      set_state(id, Hangman.State.Playing),
      set(id, :word, word)
    ]}
  end

  def new_game(word) do
    id = Pachyderm.generate_id()
    {:ok, adjustments} = creation(word, id)
    {:ok, _record} = record(Pachyderm.Ledger, adjustments, :creation)
    {:ok, id}
  end

  def guess_letter(game, letter) do
    instruct(game, %Command.Guess{letter: letter})
  end
end
