defmodule Trie do
  @moduledoc """
  Trie CRUD.
  """

  @node_bit_size 2

  def merge(trie, key) do
    key_trie = key
               |> from_key

    curr_level = find_bifurcation(trie, key_trie)
    key_exceeds_length_of_trie = curr_level == length(trie)

    if curr_level > length(trie) do
      raise "curr_level cannot ever be larger than the length(trie)"
    end

    modified_level = Enum.at(trie, curr_level)
                    |> List.replace_at(-1, {1, 1}) # both node
    trie = List.replace_at(trie, curr_level, modified_level)
    [_key_head | rest_key ] = key_trie

    do_merge(trie, rest_key, curr_level + 1)
  end

  def do_merge(trie, key_trie, curr_level) when key_trie == [] do
    trie
  end

  def do_merge(trie, key_trie, curr_level) do
    trie = if curr_level > length(trie) do
      List.insert_at(trie, -1, [])
    else
      trie
    end

    [key_head | rest_key ] = key_trie

    modified_level = Enum.at(trie, curr_level, [])
                     |> List.insert_at(-1, List.first(key_head))

    trie = if curr_level >= length(trie) do
      trie ++ [modified_level]
    else
      List.replace_at(trie, curr_level, modified_level)
    end


    do_merge(trie, rest_key, curr_level + 1)

  end

  # fixme: guard for zero length trie?
  def find_bifurcation(trie, key_trie, curr_level \\ 0)

  # if the key is already inserted
  def find_bifurcation(trie, key_trie, curr_level) when curr_level == length(key_trie), do: nil

  def find_bifurcation(trie, key_trie, curr_level) when curr_level < length(key_trie) do
    last_node = if curr_level < length(trie) do
      find_node(trie, curr_level, -1)
    else
      nil
    end

    key_exceeds_length_of_trie = last_node == nil
    key_bifurcates_trie = (last_node == {1, 0} && find_node(key_trie, curr_level, 0) == {0, 1})

    if key_exceeds_length_of_trie || key_bifurcates_trie do
      curr_level
    else
      find_bifurcation(trie, key_trie, curr_level + 1)
    end
  end


  @doc """
  Given an Elixir binary, return a trie representation whose bits are edges in a binary tree.
  Input keys traverse the tree with 0 for left and 1 for right.
  """
  def from_key(input_key) when is_binary(input_key) == false or byte_size(input_key) == 0 do
    raise "Input key must consist of whole bytes."
  end

  def from_key(input_key) do
    binary_from_key(input_key) |> binary_as_list
  end

  def binary_from_key(input_key, acc \\ <<>>)

  # done recursing
  def binary_from_key(input_key, acc) when bit_size(input_key) == 0 do
    << acc::bitstring, leaf_node::bitstring >>
  end

  def binary_from_key(input_key, acc) do
    <<target_bit::size(1), rest::bitstring>> = input_key

    acc = case target_bit do
      1 -> << acc::bitstring, Trie.right_branch_node::bitstring >>
      0 -> << acc::bitstring, Trie.left_branch_node::bitstring >>
    end

    binary_from_key(rest, acc)
  end

  @doc """
  There are two representations here: a packed binary tree (suitable for
  storage) and a list oriented form (suitable for processing). This method
  coverts from the binary form to the list form.
  """
  def binary_as_list(trie) do
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


  def find_node(trie, target_level, j_node) when target_level >= length(trie) do
    raise ArgumentError, message: "target_level exceed the len of the longest key."
  end

  def find_node(trie, target_level, j_node) do
    trie
    |> Enum.at(target_level)
    |> Enum.at(j_node)
  end

  def do_find_node(trie, target_level, target_node, nodes_in_level, curr_level, accum_bit_offset) when target_level == curr_level do
    bit_offset = target_node * 2 + accum_bit_offset
    <<_offset::size(bit_offset), node::size(2), _rest::bitstring>> = trie
    node
  end

  def left_branch_node do
    <<1::size(1), 0::size(1)>>
  end

  def right_branch_node do
    <<0::size(1), 1::size(1)>>
  end

  def both_branch_node do
    <<1::size(1), 1::size(1)>>
  end

  def leaf_node do
    <<0::size(1), 0::size(1)>>
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
