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
    node = find_node_on_level(level, curr_index)
    <<lhs::integer-size(1), rhs::integer-size(1)>> = node

    lhs + rhs + outbound_links(level, prior_to_node_index, curr_index + 1)
  end

  def all_keys(trie) do
    # accumulate a key by traversing down to a leaf
    # call function on each discovered key
    iter_tree(trie, 0, 0, <<>>)
  end

  def iter_tree(trie, curr_level, j_node, accum) do
    curr_node = find_node(trie, curr_level, j_node)

    res = if curr_node == @leaf_node do
      [accum]
    else
      prev_children = Enum.at(trie, curr_level)
      |> outbound_links(j_node)
      <<lhs::integer-size(1), rhs::integer-size(1)>> = curr_node

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

    merge_key_trie(trie, key_trie)
  end

  def merge_key_trie(trie, key_trie) do

    curr_level = find_bifurcation(trie, key_trie)

    if curr_level == nil do
      trie
    else

      if curr_level > length(trie) do
        raise "bifucation cannot occur after the longest key in trie"
      end

      trie = set_both_branch_node(trie, curr_level)

      merge_level(trie, key_trie, curr_level + 1)
    end

  end

  def merge_level(trie, key_trie, curr_level) do
    if curr_level == length(key_trie) do
      trie
    else
      node_to_append = find_node(key_trie, curr_level, 0)

      merge_level(append_node(trie, curr_level, node_to_append), key_trie, curr_level + 1)
    end
  end


  def resize_for_level(trie, i_level) do
    if i_level == length(trie) do
      trie ++ [{0, <<>>}]
    else
      trie
    end
  end

  def append_node(trie, i_level, node_to_append) do
    trie = resize_for_level(trie, i_level)

    {ct, bits} = Enum.at(trie, i_level)

    level_bit_size = ct * @node_bit_size
    new_level = {ct + 1, <<bits::bitstring-size(level_bit_size), node_to_append::bitstring-size(@node_bit_size)>> }
    List.replace_at(trie, i_level, new_level)
  end

  def set_both_branch_node(trie, i_level) do
    trie = resize_for_level(trie, i_level)
    {ct, bits} = Enum.at(trie, i_level)
    bit_offset = if ct == 0 do
      0
    else
      (ct - 1) * @node_bit_size
    end

    total_bits = ct * @node_bit_size
    << leading_nodes::bitstring-size(bit_offset), _skip_node::2 >> = << bits::bitstring-size(total_bits) >>

    with_node = @both_branch_node
    
    new_level = {ct, <<leading_nodes::bitstring-size(bit_offset), with_node::bitstring-size(@node_bit_size)>> }
    List.replace_at(trie, i_level, new_level)
  end


  def find_bifurcation(trie, key_trie, curr_level \\ 0)

  def find_bifurcation(trie, key_trie, curr_level) do


    cond do
      curr_level == length(key_trie) ->
        nil
      curr_level < length(key_trie) ->
        last_node_of_trie = if curr_level < length(trie) do
          {node_count, _} = Enum.at(trie, curr_level)
          find_node(trie, curr_level, node_count - 1)
        else
          nil
        end

        curr_node_key_trie = find_node(key_trie, curr_level, 0)

        key_exceeds_length_of_trie = last_node_of_trie == nil

        <<t1::bitstring-size(1), t2::bitstring-size(1)>> = last_node_of_trie
        <<k1::bitstring-size(1), k2::bitstring-size(1)>> = curr_node_key_trie

        key_bifurcates_trie = (k2 != t2) || (last_node_of_trie == @leaf_node && curr_node_key_trie != @leaf_node)

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
    trie_list = input_key_list |> Enum.map(fn(key)-> Trie.from_key(key) end)
    Enum.reduce(trie_list,  fn(val, trie) -> Trie.merge_key_trie(trie, val)  end)
  end

  @doc """
  Given an Elixir binary, return a trie representation whose bits are edges in a binary tree.
  Input keys traverse the tree with 0 for left and 1 for right.
  """
  def from_key(input_key) when is_binary(input_key) == false or byte_size(input_key) == 0 do
    raise "Input key must consist of whole bytes."
  end

  def from_key(input_key) do
    binary_from_key(input_key) |> binary_as_trie
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
  def binary_as_trie(trie) do
    array_len = Kernel.trunc(bit_size(trie) / 2.0)
    do_as_array(trie, 0, 1, [])
  end

  defp do_as_array(trie_fragment, level_index, j_nodes_curr_level, accum) when bit_size(trie_fragment) == 0 do
    Enum.reverse(accum)
  end

  defp do_as_array(trie_fragment, level_index, j_nodes_curr_level, accum) do

    trie_level_slice_size = j_nodes_curr_level * @node_bit_size

    << trie_level_slice::bitstring-size(trie_level_slice_size), rest_trie::bitstring >> = << trie_fragment::bitstring >>

    j_children_counts = length(for <<b :: 1 <- <<trie_level_slice::bitstring-size(trie_level_slice_size)>>  >>, b > 0, do: b)

    do_as_array(rest_trie,
               level_index + 1,
               j_children_counts,
               [{j_nodes_curr_level, trie_level_slice}| accum])
  end

  def as_list(trie) do
    trie
    |> Enum.map(fn({size, level_bitstring}) ->
      do_as_list(level_bitstring, size)
    end)
  end

  defp do_as_list(trie_level_slice, j_nodes_curr_level) do
    trie_level_slice_size = j_nodes_curr_level * @node_bit_size

    nodes_for_level = (for <<b :: 2 <- <<trie_level_slice::bitstring-size(trie_level_slice_size)>>  >>, do: b)

    expanded_nodes = nodes_for_level
    |> Enum.map(fn(node) ->
      <<lhs::size(1), rhs::size(1)>> = <<node::size(2)>>
      {lhs, rhs}
    end)


    expanded_nodes
  end

  # Nodes

  def find_node(trie, target_level, j_node) do
    cond do
      length(trie) == 0 ->
        raise ArgumentError, message: "Trie must not be empty."
      target_level >= length(trie) ->
        raise ArgumentError, message: "target_level exceed the len of the longest key."
      true ->
        level = Enum.at(trie, target_level)
        find_node_on_level(level, j_node)

    end
  end

  def find_node_on_level(level, j_node) do
    {node_count, bits} = level

    bit_offset = j_node * 2
    level_bits = node_count * 2
    <<_offset::bitstring-size(bit_offset), target_node::bitstring-size(2), _rest::bitstring>> = <<bits::bitstring-size(level_bits)>>
    target_node
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
