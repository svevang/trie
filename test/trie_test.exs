defmodule TrieTest do
  use ExUnit.Case
  doctest Trie


  describe "set_both_branch_node/2" do
    test "it can replace a level's last node in a trie" do
      a_byte = <<97>>
      assert (Trie.from_key(a_byte)) |> Trie.set_both_branch_node(0) |> Trie.as_list == [[{1, 1}], [{0, 1}], [{0, 1}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{0, 1}], [{0, 0}]]
      assert (Trie.from_key(a_byte)) |> Trie.set_both_branch_node(1) |> Trie.as_list == [[{1, 0}], [{1, 1}], [{0, 1}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{0, 1}], [{0, 0}]]
    end
  end

  describe "append_node/2" do
    test "it can append a node to a trie's level" do
      a_byte = <<97>>
      assert (Trie.from_key(a_byte)) |> Trie.append_node(0, <<0::8, 0::8>>) |> Trie.as_list == [[{1, 0}, {0, 0}], [{0, 1}], [{0, 1}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{0, 1}], [{0, 0}]]
    end
  end

  describe "binary_as_trie/1" do
    test "it can print out a node as a trie fragment (missing leaf node)" do
      assert <<1::8, 0::8>> |> Trie.binary_as_trie |> Trie.as_list == [[{1, 0}]]
      assert <<0::8, 0::8>> |> Trie.binary_as_trie |> Trie.as_list == [[{0, 0}]]

      # examine a rawtrie entry
      arr = <<0::8, 0::8>> |> Trie.binary_as_trie
      assert Trie.at(arr, 0) == {1, <<0, 0>>}
    end
  end

  describe "from_key/1" do
    test "Sets up a new trie" do
      a_byte = <<97>>
      assert (Trie.from_key(a_byte)) |> Trie.as_list == [[{1, 0}], [{0, 1}], [{0, 1}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{0, 1}], [{0, 0}]]
    end

    test "empty byte" do
      all_zero_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>
      assert (Trie.from_key(all_zero_byte)) |> Trie.as_list == [[{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{0, 0}]]
    end

    test "filled byte" do
      all_one_byte = <<1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1>>
      assert (Trie.from_key(all_one_byte)) |> Trie.as_list == [[{0, 1}], [{0, 1}], [{0, 1}], [{0, 1}], [{0, 1}], [{0, 1}], [{0, 1}], [{0, 1}], [{0, 0}]]
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

      assert Trie.find_node(trie, 0, 0) == <<0, 1>>
      assert Trie.find_node(trie, 1, 0) == <<1, 0>>
    end

    test "checks bounds" do
      key_byte = <<1::1, 0::1, 0::1, 0::1, 1::1, 0::1, 0::1, 0::1>>
      trie = Trie.from_key(key_byte)

      assert_raise(ArgumentError, fn() ->
        Trie.find_node(trie, 9, 0)
      end)
      assert_raise(ArgumentError, fn() ->
        Trie.find_node(%{}, 0, 0)
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
      # Here we are seeing the bifurcation just after the end of the current trie on the leaf node
      assert 9 == Trie.size(base_trie)
    end

  end

  describe "merge/2" do

    test "merges a key into a trie" do
      all_one_byte = <<1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1>>
      all_zero_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>
      # [[{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}]]
      trie = Trie.from_key(all_zero_byte) 
      assert Trie.merge(trie, all_one_byte)|> Trie.as_list == [[{1, 1}],
                                                [{1, 0}, {0, 1}],
                                                [{1, 0}, {0, 1}],
                                                [{1, 0}, {0, 1}],
                                                [{1, 0}, {0, 1}],
                                                [{1, 0}, {0, 1}],
                                                [{1, 0}, {0, 1}],
                                                [{1, 0}, {0, 1}],
                                                [{0, 0}, {0, 0}]
      ]
    end

    test "merges a key of longer length into a trie" do
      all_one_byte = <<1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1>>
      all_zero_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>
      # [[{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}], [{1, 0}]]
      trie = Trie.from_key(all_zero_byte) 
      assert Trie.merge(trie, all_one_byte <> all_one_byte) |> Trie.as_list == [
        [{1, 1}],
        [{1, 0}, {0, 1}],
        [{1, 0}, {0, 1}],
        [{1, 0}, {0, 1}],
        [{1, 0}, {0, 1}],
        [{1, 0}, {0, 1}],
        [{1, 0}, {0, 1}],
        [{1, 0}, {0, 1}],
        [{0, 0}, {0, 1}],
        [{0, 1}],
        [{0, 1}],
        [{0, 1}],
        [{0, 1}],
        [{0, 1}],
        [{0, 1}],
        [{0, 1}],
        [{0, 0}]]
    end

    test "merging a key already in the trie does nothing" do

      all_one_byte = <<1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1>>
      all_zero_byte = <<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>

      assert Trie.from_key(all_zero_byte)
      |> Trie.merge(all_one_byte)
      |> Trie.merge(all_one_byte) |> Trie.as_list ==
        Trie.from_key(all_zero_byte)
        |> Trie.merge(all_one_byte)
        |> Trie.as_list 

    end

    test "key to merge's head node is beyond the length of the current trie" do
      assert Trie.from_key("A") |> Trie.merge("Aani")
    end

  end

  describe "outbound_links/2" do
    test "sums outbound_links previous to this node" do
      assert Trie.outbound_links({4, <<0::8, 0::8, 0::8, 1::8, 1::8, 0::8, 0::8, 0::8>>}, 3) == 2

    end
  end

  describe "all_keys/2" do
    test "returns a list of all keys in the trie" do
      trie = Trie.from_key("asdf")
      |> Trie.merge("qwer")
      assert Trie.all_keys(trie) == ["asdf", "qwer"]
    end

    test "handles keys of a single byte" do
      trie = Trie.from_key("A")
      |> Trie.merge("qwer")
      assert Trie.all_keys(trie) == ["A", "qwer"]
    end

    test "returns bytes for null and max node" do

      trie = Trie.from_key(<<0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>)
      trie = Trie.merge(trie, <<1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1>>)

      assert Trie.all_keys(trie) == [<<0::unsigned-integer-size(8)>>, <<255::unsigned-integer-size(8)>>]
    end
  end

  describe "bit_at_index/2" do
    test 'it returns the bit at an index' do
      assert Trie.bit_at_index(<<1::1, 0::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1>>, 1) == 0
      assert Trie.bit_at_index(<<1::1, 0::1, 1::1, 1::1, 1::1, 1::1, 1::1, 1::1>>, 0) == 1
      assert Trie.bit_at_index("pre", 0) == 0
      assert Trie.bit_at_index("pre", 1) == 1
      assert Trie.bit_at_index("pre", 2) == 1
    end
  end

  describe "prefix_search/2" do
    test "returns a list of matching keys based on the prefix" do


      trie = ~w(Aani Aaron Aaronic Aaronical Aaronite Aaronitic Aaru Ab Ababdeh Ababua)
             |> Enum.sort
             |> Trie.from_keys

      matches = ~w(Aani Aaron Aaronic Aaronical Aaronite Aaronitic Aaru Ab Ababdeh Ababua)
              |> Enum.sort
              |> Trie.from_keys
              |> Trie.prefix_search("Aar")
      assert matches == ~w(Aaron Aaronic Aaronical Aaronite Aaronitic Aaru)
    end
  end
end
