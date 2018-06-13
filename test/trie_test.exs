defmodule TrieTest do
  use ExUnit.Case
  doctest Trie

  describe "from_keye/1" do
    test "Sets up a new trie" do
      a_byte = <<97>>
      assert (Trie.from_key(a_byte) |> Trie.as_list) == [[1, 0], [0, 1], [0, 1], [1, 0], [1, 0], [1, 0], [1, 0], [0, 1]]
    end

    test "empty byte" do
      all_zero_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>
      assert (Trie.from_key(all_zero_byte) |> Trie.as_list) == [[1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0]]
    end

    test "filled byte" do
      all_one_byte = <<1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1>>
      assert (Trie.from_key(all_one_byte) |> Trie.as_list) == [[0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1]]
    end

    test "only accepts keys composed of whole bytes" do
      assert_raise RuntimeError, ~r/^Input key must consist of whole bytes.$/, fn ->
        Trie.from_key(<<1::size(1)>>)
      end
      assert_raise RuntimeError, ~r/^Input key must consist of whole bytes.$/, fn ->
        Trie.from_key(<<>>)
      end
    end

  end
end
