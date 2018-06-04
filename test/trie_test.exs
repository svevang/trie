defmodule TrieTest do
  use ExUnit.Case
  doctest Trie

  describe "create_unsorted/2" do
    test "Sets up a new trie" do
      words = ["another", "fine", "test"]
      {:ok, trie_file} = Trie.create_unsorted(words, "/tmp/test.trie")
    end
  end
end
