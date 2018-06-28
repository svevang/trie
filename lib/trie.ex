defmodule Trie do
  @moduledoc """
  Trie CRUD.
  """

  @node_bit_size 2

  #def merge(trie, key) do
    #root_level = 1
    #do_merge(trie, key, root_level, ast)
  #end

  #def find_bifurcation(trie, key, curr_level, last) do
    #leaf_level = length(key) + 1
  #end


  @doc """
  Given an Elixir binary, return a trie representation whose bits are edges in a binary tree.
  Input keys traverse the tree with 0 for left and 1 for right.
  """
  def from_key(input_key) when is_binary(input_key) == false or byte_size(input_key) == 0 do
    raise "Input key must consist of whole bytes."
  end

  def from_key(input_key) do
    do_from_key(input_key)
  end

  def do_from_key(input_key, acc \\ <<>>)

  # done recursing
  def do_from_key(input_key, acc) when bit_size(input_key) == 0 do
    acc
  end

  def do_from_key(input_key, acc) do
    <<target_bit::size(1), rest::bitstring>> = input_key

    acc = case target_bit do
      1 -> << acc::bitstring, Trie.right_branch::bitstring >>
      0 -> << acc::bitstring, Trie.left_branch::bitstring >>
    end

    do_from_key(rest, acc)
  end

  def as_list(trie) do
    do_as_list(trie, 0, 1)
  end

  defp do_as_list(trie_fragment, level_index, j_nodes_curr_level) when bit_size(trie_fragment) == 0 do
    []
  end

  defp do_as_list(trie_fragment, level_index, j_nodes_curr_level) do

    trie_level_slice_size = j_nodes_curr_level * @node_bit_size

    << trie_level_slice::size(trie_level_slice_size), rest_trie::bitstring >> = << trie_fragment::bitstring >>

    nodes_for_level = (for <<b :: 2 <- <<trie_level_slice::size(trie_level_slice_size)>>  >>, do: b)

    {expanded_nodes, j_children_counts} = nodes_for_level
    |> Enum.map(fn(node) ->
      <<lhs::size(1), rhs::size(1)>> = <<node::size(2)>>
      {{lhs, rhs}, lhs + rhs}
    end)
    |> Enum.unzip

    [expanded_nodes | do_as_list(rest_trie, level_index + 1, Enum.sum(j_children_counts))] 
  end


  @doc """
  Returns the direct children of the trie.
  """
  def find_node(trie, target_level, j_node) do
    trie
    |> as_list
    |> Enum.at(target_level)
    |> Enum.at(j_node)

  end

  def do_find_node(trie, target_level, target_node, nodes_in_level, curr_level, accum_bit_offset) when target_level == curr_level do
    bit_offset = target_node * 2 + accum_bit_offset
    <<_offset::size(bit_offset), node::size(2), _rest::bitstring>> = trie
    node
  end

  def left_branch do
    <<1::size(1), 0::size(1)>>
  end

  def right_branch do
    <<0::size(1), 1::size(1)>>
  end

  @doc """
  iex> Trie.bit_at_index(<<255>>, 7)
  1
  iex> Trie.bit_at_index(<<254>>, 7)
  0
  """
  def bit_at_index(bin, index) when is_binary(bin) == false
                               when byte_size(bin) == 0
                               when index < 0
                               when index >= bit_size(bin) do
    raise "Bad argument"
  end

  def bit_at_index(bin, index) do
    leading = index
    trailing = bit_size(bin) - leading - 1
    <<_::size(leading), target_bit::size(1), _::size(trailing) >> = bin
    target_bit
  end

end
