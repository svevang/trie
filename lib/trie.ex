defmodule Trie do
  @moduledoc """
  Trie CRUD.
  """

  @node_bit_size 2

  @left_branch_node <<1::size(1), 0::size(1)>>
  @right_branch_node <<0::size(1), 1::size(1)>>
  @both_branch_node <<1::size(1), 1::size(1)>>
  @leaf_node <<0::size(1), 0::size(1)>>

  def outbound_links(level, prior_to_node_index, curr_index \\ 0)

  def outbound_links(level, prior_to_node_index, curr_index) when curr_index == prior_to_node_index do
    0
  end

  def outbound_links(level, prior_to_node_index, curr_index) do
    node = Enum.at(level, curr_index)
    {lhs, rhs} = node

    lhs + rhs + outbound_links(level, prior_to_node_index, curr_index + 1)
  end

  def all_keys(trie) do
    # accumulate a key by traversing down to a leaf
    # call function on each discovered key
    iter_tree(trie, 0, 0, <<>>)
  end

  def iter_tree(trie, curr_level, j_node, accum) do
    curr_node = find_node(trie, curr_level, j_node)

    res = if curr_node == {0, 0} do
      [accum]
    else
      prev_children = Enum.at(trie, curr_level)
      |> outbound_links(j_node)
      {lhs, rhs} = curr_node

      branch_results = []
      branch_results = if lhs == 1 do
        iter_tree(trie, curr_level + 1, prev_children, <<accum::bitstring, 0::size(1)>>)
      else
        []
      end

      branch_results = branch_results ++ if rhs == 1 do
        iter_tree(trie, curr_level + 1, prev_children + lhs, <<accum::bitstring, 1::size(1)>>)
      else
        []
      end

      branch_results
    end


  end

  def merge(trie, key) do
    key_trie = key
               |> from_key

    curr_level = find_bifurcation(trie, key_trie)

    if curr_level == nil do
      trie
    else
      # fast forward down to the mergeable nodes
      key_trie = Enum.drop(key_trie, curr_level)

      modified_node = Enum.at(trie, curr_level, [])
                       |> List.replace_at(-1, {1, 1})
      trie = List.replace_at(trie, curr_level, modified_node)
      [_key_head | rest_key ] = key_trie

      do_merge(trie, rest_key, curr_level + 1)
    end

  end

  def do_merge(trie, key_trie, curr_level) when key_trie == [] do
    trie
  end

  def modify_trie(trie, curr_level, modified_level) do
    trie = if curr_level >= length(trie) do
      trie ++ [modified_level]
    else
      List.replace_at(trie, curr_level, modified_level)
    end
  end

  def modify_level(trie, curr_level, node) do
    modified_level = Enum.at(trie, curr_level, [])
                     |> List.insert_at(-1, node)
  end

  def do_merge(trie, key_trie, curr_level) do
    [key_head | rest_key ] = key_trie

    modified_level = modify_level(trie, curr_level, List.first(key_head))

    trie = modify_trie(trie, curr_level, modified_level)

    do_merge(trie, rest_key, curr_level + 1)

  end

  def find_bifurcation(trie, key_trie, curr_level \\ 0)

  def find_bifurcation(trie, key_trie, curr_level) do

    cond do
      curr_level == :array.size(key_trie) ->
        nil
      curr_level < :array.size(key_trie) ->
        last_node = if curr_level < :array.size(trie) do
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
  end

  @doc """
  Given a list of Elixir binaries, return a trie representation whose bits are edges in a binary tree.
  Input keys traverse the tree with 0 for left and 1 for right.
  """
  def from_keys(input_key_list, trie \\ nil) when is_list(input_key_list) do
    {head_el, rest} = List.pop_at(input_key_list, 0)
    t = from_key(head_el)
    [t | rest] |> Enum.reduce(fn(val, trie) -> Trie.merge(trie, val)  end)
  end

  @doc """
  Given an Elixir binary, return a trie representation whose bits are edges in a binary tree.
  Input keys traverse the tree with 0 for left and 1 for right.
  """
  def from_key(input_key) when is_binary(input_key) == false or byte_size(input_key) == 0 do
    raise "Input key must consist of whole bytes."
  end

  def from_key(input_key) do
    binary_from_key(input_key) |> binary_as_array
  end

  def binary_from_key(input_key, acc \\ <<>>)

  # done recursing
  def binary_from_key(input_key, acc) when bit_size(input_key) == 0 do
    << acc::bitstring, @leaf_node::bitstring >>
  end

  def binary_from_key(input_key, acc) do
    <<target_bit::size(1), rest::bitstring>> = input_key

    acc = case target_bit do
      1 -> << acc::bitstring, @right_branch_node::bitstring >>
      0 -> << acc::bitstring, @left_branch_node::bitstring >>
    end

    binary_from_key(rest, acc)
  end

  @doc """
  There are two representations here: a packed binary tree (suitable for
  storage) and a list oriented form (suitable for processing). This method
  coverts from the binary form to the list form.
  """
  def binary_as_array(trie) do
    array_len = Kernel.trunc(bit_size(trie) / 2.0)
    do_as_array(trie, 0, 1, :array.new([{:size, array_len}, {:fixed, true}]))
  end

  defp do_as_array(trie_fragment, level_index, j_nodes_curr_level, accum) when bit_size(trie_fragment) == 0 do
    accum
  end

  defp do_as_array(trie_fragment, level_index, j_nodes_curr_level, accum) do

    trie_level_slice_size = j_nodes_curr_level * @node_bit_size

    << trie_level_slice::size(trie_level_slice_size), rest_trie::bitstring >> = << trie_fragment::bitstring >>

    j_children_counts = length(for <<b :: 1 <- <<trie_level_slice::size(trie_level_slice_size)>>  >>, b > 0, do: b)

    do_as_array(rest_trie,
               level_index + 1,
               j_children_counts,
               :array.set(level_index, {j_nodes_curr_level, trie_level_slice}, accum))
  end

  # Nodes

  def find_node(trie, target_level, j_node) do
    cond do
      :array.size(trie) == 0 ->
        raise ArgumentError, message: "Trie must not be empty."
      target_level >= :array.size(trie) ->
        raise ArgumentError, message: "target_level exceed the len of the longest key."
      true ->
        {node_count, level} = :array.get(target_level, trie)
        bit_offset = j_node * 2
        level_bits = node_count * 2
        <<_offset::size(bit_offset), target_node::size(2), _rest::bitstring>> = <<level::size(level_bits)>>
        target_node
    end
  end

  def do_find_node(trie, target_level, target_node, nodes_in_level, curr_level, accum_bit_offset) when target_level == curr_level do
    bit_offset = target_node * 2 + accum_bit_offset
    <<_offset::size(bit_offset), node::size(2), _rest::bitstring>> = trie
    node
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
