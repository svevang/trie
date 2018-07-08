defmodule TrieTest do
  use ExUnit.Case
  doctest Trie


  describe "binary_as_list/1" do
    test "it can print out a node as a single node trie" do
      assert <<1::1, 0::1>> |> Trie.binary_as_list == [[{1, 0}]]
      assert <<0::1, 0::1>> |> Trie.binary_as_list == [[{0, 0}]]
    end
  end

  describe "from_key/1" do
    test "Sets up a new trie" do
      a_byte = <<97>>
      assert (Trie.from_key(a_byte)) == [[{1, 0}], [{0, 1}], [{0, 1}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{0, 1}]]
    end

    test "empty byte" do
      all_zero_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>
      assert (Trie.from_key(all_zero_byte)) == [[{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}]]
    end

    test "filled byte" do
      all_one_byte = <<1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1>>
      assert (Trie.from_key(all_one_byte)) == [[{0, 1}], [{0, 1}], [{0, 1}], [{0, 1}], [{0, 1}], [{0, 1}], [{0, 1}], [{0, 1}]]
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

  describe "find_node/3" do
    test "finds the root node" do
      key_byte = <<1::1, 0::1, 0::1, 0::1, 1::1, 0::1, 0::1, 0::1>>
      trie = Trie.from_key(key_byte)

      assert Trie.find_node(trie, 0, 0) == {0, 1}
      assert Trie.find_node(trie, 1, 0) == {1, 0}
      assert_raise(ArgumentError, fn() ->
        Trie.find_node(trie, 8, 0)
      end)
    end
  end

  describe "find_bifurcation/2" do
    test "finds a bifurcation at the beginning" do
      all_zero_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>
      all_one_byte = <<1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1>>
      base_trie =  Trie.from_key(all_zero_byte)
      key_trie =  Trie.from_key(all_one_byte)

      assert Trie.find_bifurcation(base_trie, key_trie) == 0
    end

    test "finds a bifurcation at the middle" do
      base_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>
      key_byte = <<0::1, 0::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1>>
      base_trie =  Trie.from_key(base_byte)
      key_trie =  Trie.from_key(key_byte)

      assert Trie.find_bifurcation(base_trie, key_trie) == 2
    end

    test "finds a bifurcation at the end" do
      base_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>
      key_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 1::1>>
      base_trie =  Trie.from_key(base_byte)
      key_trie =  Trie.from_key(key_byte)

      assert Trie.find_bifurcation(base_trie, key_trie) == 7
    end

    test "finds no bifurcation if key is in tree" do
      base_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>
      key_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>
      base_trie =  Trie.from_key(base_byte)
      key_trie =  Trie.from_key(key_byte)

      assert Trie.find_bifurcation(base_trie, key_trie) == nil
    end

    test "finds bifurcation if key is longer than tree" do
      # both are all zeros
      base_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>
      key_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>
      base_trie =  Trie.from_key(base_byte)
      key_trie =  Trie.from_key(key_byte)

      assert Trie.find_bifurcation(base_trie, key_trie) == 8
      #Here we are seeing the bifurcation just after the end of the current trie
      assert 8 == length(base_trie)
    end

  end

  describe "merge/2" do

    test "merges a key into a trie" do
      all_one_byte = <<1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1>>
      all_zero_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>
      # [[{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}]]
      trie = Trie.from_key(all_zero_byte) 
      assert Trie.merge(trie, all_one_byte) == [:fixme]
    end

  end


end
