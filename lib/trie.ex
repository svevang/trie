defmodule Trie do
  @moduledoc """
  Trie CRUD.
  """

  @node_bit_size 16
  @branch_bit_size 8

  @left_branch_node <<1::size(8), 0::size(8)>>
  @right_branch_node <<0::size(8), 1::size(8)>>
  @both_branch_node <<1::size(8), 1::size(8)>>
  @leaf_node <<0::size(8), 0::size(8)>>

  def outbound_links(level, prior_to_node_index, curr_index \\ 0)

  def outbound_links(_, prior_to_node_index, curr_index) when curr_index == prior_to_node_index do
    0
  end

  def outbound_links(level, prior_to_node_index, curr_index) do
    node = find_node_on_level(level, curr_index)
    <<lhs::integer-size(@branch_bit_size), rhs::integer-size(@branch_bit_size)>> = node

    lhs + rhs + outbound_links(level, prior_to_node_index, curr_index + 1)
  end

  def all_keys(trie) do
    # accumulate a key by traversing down to a leaf
    # call function on each discovered key
    iter_tree(trie, 0, 0, <<>>)
  end

  def iter_tree(trie, curr_level, j_node, accum) do
    curr_node = find_node(trie, curr_level, j_node)

    if curr_node == @leaf_node do
      [accum]
    else
      prev_children =
        Trie.at(trie, curr_level)
        |> outbound_links(j_node)

      <<lhs::integer-size(@branch_bit_size), rhs::integer-size(@branch_bit_size)>> = curr_node

      branch_results =
        if lhs == 1 do
          iter_tree(trie, curr_level + 1, prev_children, <<accum::bitstring, 0::size(1)>>)
        else
          []
        end

      branch_results =
        branch_results ++
          if rhs == 1 do
            iter_tree(trie, curr_level + 1, prev_children + lhs, <<accum::bitstring, 1::size(1)>>)
          else
            []
          end

      branch_results
    end
  end

  def prefix_search(trie, prefix) do
    IO.puts "Starting:"
    IO.inspect all_keys(trie)
    prefix_search(trie, prefix, 0, 0)
  end

  defp prefix_search(trie, prefix, curr_level, j_node) when curr_level == bit_size(prefix)  do
      raise('found prefix')
  end
  defp prefix_search(trie, prefix, curr_level, j_node) do
    curr_node = find_node(trie, curr_level, j_node)
    <<lhs::integer-size(@branch_bit_size), rhs::integer-size(@branch_bit_size)>> = curr_node

    prev_children =
      Trie.at(trie, curr_level)
      |> outbound_links(j_node)

    IO.inspect "bit: #{bit_at_index(prefix, curr_level)} curr:#{curr_level} lhs:#{lhs} rhs:#{rhs}"

    if bit_at_index(prefix, curr_level) == 0 do
        if lhs == 1 do
          prefix_search(trie, prefix, curr_level + 1, prev_children)
        else
          raise "prefix not found!"
        end
    else
        if rhs == 1 do
          prefix_search(trie, prefix, curr_level + 1, prev_children)
        else
          raise "prefix not found!"
        end
    end


  end


  def merge(trie, key) do
    key_trie =
      key
      |> from_key

    merge_key_trie(trie, key_trie)
  end

  def merge_key_trie(trie, key_trie) do
    curr_level = find_bifurcation(trie, key_trie)

    if curr_level == nil do
      trie
    else
      if curr_level > Trie.size(trie) do
        raise "bifucation cannot occur after the longest key in trie"
      end

      trie = set_both_branch_node(trie, curr_level)

      merge_level(trie, key_trie, curr_level + 1)
    end
  end

  def merge_level(trie, key_trie, curr_level) do
    if curr_level == Trie.size(key_trie) do
      trie
    else
      node_to_append = find_node(key_trie, curr_level, 0)

      merge_level(append_node(trie, curr_level, node_to_append), key_trie, curr_level + 1)
    end
  end

  def append_node(trie, i_level, node_to_append) do
    trie = resize_for_level(trie, i_level)

    {ct, bits} = Trie.at(trie, i_level)

    level_bit_size = ct * @node_bit_size

    new_level =
      {ct + 1,
       <<bits::bitstring-size(level_bit_size), node_to_append::bitstring-size(@node_bit_size)>>}

    Trie.replace_at(trie, i_level, new_level)
  end

  def set_both_branch_node(trie, i_level) do
    trie = resize_for_level(trie, i_level)
    {ct, bits} = Trie.at(trie, i_level)

    bit_offset =
      if ct == 0 do
        0
      else
        (ct - 1) * @node_bit_size
      end

    total_bits = ct * @node_bit_size

    <<leading_nodes::bitstring-size(bit_offset), _skip_node::@node_bit_size>> =
      <<bits::bitstring-size(total_bits)>>

    with_node = @both_branch_node

    new_level =
      {ct,
       <<leading_nodes::bitstring-size(bit_offset), with_node::bitstring-size(@node_bit_size)>>}

    Trie.replace_at(trie, i_level, new_level)
  end

  def find_bifurcation(trie, key_trie, curr_level \\ 0)

  def find_bifurcation(trie, key_trie, curr_level) do
    cond do
      curr_level == Trie.size(key_trie) ->
        nil

      curr_level < Trie.size(key_trie) ->
        last_node_of_trie =
          if curr_level < Trie.size(trie) do
            {node_count, _} = Trie.at(trie, curr_level)
            find_node(trie, curr_level, node_count - 1)
          else
            nil
          end

        curr_node_key_trie = find_node(key_trie, curr_level, 0)

        key_exceeds_length_of_trie = last_node_of_trie == nil

        <<_::bitstring-size(8), t2::bitstring-size(8)>> = last_node_of_trie
        <<_::bitstring-size(8), k2::bitstring-size(8)>> = curr_node_key_trie

        key_bifurcates_trie =
          k2 != t2 || (last_node_of_trie == @leaf_node && curr_node_key_trie != @leaf_node)

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
  def from_keys([head | tail] = input_key_list) when is_list(input_key_list) do
    do_from_keys(tail, Trie.from_key(head))
  end


  defp do_from_keys([head | tail], trie) do
    do_from_keys(tail, Trie.merge(trie, head))
  end

  defp do_from_keys([], trie) do
    trie
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

  def binary_from_key(input_key) do
    binary_from_key(input_key, bit_size(input_key))
  end

  def binary_from_key(input_key, key_bit_len, acc \\ <<>>)

  def binary_from_key(<<>>, 0, acc) do
    <<acc::bitstring, @leaf_node::bitstring>>
  end

  def binary_from_key(input_key, key_bit_len, acc) do
    rest_bit_len = key_bit_len - 1
    <<target_bit::size(1), rest::bitstring-size(rest_bit_len)>> = input_key

    acc =
      case target_bit do
        1 -> <<acc::bitstring, @right_branch_node::bitstring>>
        0 -> <<acc::bitstring, @left_branch_node::bitstring>>
      end

    binary_from_key(rest, rest_bit_len, acc)
  end

  def as_list(trie) do
    0..(Trie.size(trie) - 1)
    |> Enum.map(fn i ->
      {size, level_bitstring} = Trie.at(trie, i)
      do_as_list(level_bitstring, size)
    end)
  end

  defp do_as_list(trie_level_slice, j_nodes_curr_level) do
    trie_level_slice_size = j_nodes_curr_level * @node_bit_size

    nodes_for_level =
      for <<(b::@node_bit_size <- <<trie_level_slice::bitstring-size(trie_level_slice_size)>>)>>,
        do: b

    expanded_nodes =
      nodes_for_level
      |> Enum.map(fn node ->
        <<lhs::size(@branch_bit_size), rhs::size(@branch_bit_size)>> =
          <<node::size(@node_bit_size)>>

        {lhs, rhs}
      end)

    expanded_nodes
  end

  # Nodes

  def find_node(trie, target_level, j_node) do
    cond do
      Trie.size(trie) == 0 ->
        raise ArgumentError, message: "Trie must not be empty."

      target_level >= Trie.size(trie) ->
        raise ArgumentError, message: "target_level exceed the len of the longest key."

      true ->
        level = Trie.at(trie, target_level)
        find_node_on_level(level, j_node)
    end
  end

  def find_node_on_level(level, j_node) do
    {node_count, bits} = level

    bit_offset = j_node * @node_bit_size
    level_bits = node_count * @node_bit_size

    <<_offset::bitstring-size(bit_offset), target_node::bitstring-size(@node_bit_size),
      _rest::bitstring>> = <<bits::bitstring-size(level_bits)>>

    target_node
  end

  @doc """
  iex> Trie.bit_at_index(<<255>>, 7)
  1
  iex> Trie.bit_at_index(<<254>>, 7)
  0
  """
  def bit_at_index(bin, index)
      when is_binary(bin) == false
      when byte_size(bin) == 0
      when index < 0
      when index >= bit_size(bin) do
    raise "Bad argument"
  end

  def bit_at_index(bin, index) do
    leading = index
    trailing = bit_size(bin) - leading - 1
    <<_::size(leading), target_bit::size(1), _::size(trailing)>> = bin
    target_bit
  end

  # REPR

  def at(trie, index) do
    trie[index]
  end

  def size(trie) do
    map_size(trie)
  end

  def resize_for_level(trie, i_level) do
    if i_level == Trie.size(trie) do
      Trie.replace_at(trie, i_level, {0, <<>>})
    else
      trie
    end
  end

  def replace_at(trie, i_level, value) do
    Map.put(trie, i_level, value)
  end

  def binary_as_trie(trie) do
    do_as_trie(trie, 0, 1, %{}, bit_size(trie))
  end

  defp do_as_trie(trie_fragment, _, _, accum, _) when bit_size(trie_fragment) == 0 do
    accum
  end

  defp do_as_trie(trie_fragment, level_index, j_nodes_curr_level, accum, trie_fragment_byte_size) do
    trie_level_slice_size = j_nodes_curr_level * @node_bit_size

    rest_size = trie_fragment_byte_size - trie_level_slice_size

    <<trie_level_slice::bitstring-size(trie_level_slice_size),
      rest_trie::bitstring-size(rest_size)>> = <<trie_fragment::bitstring>>

    j_children_counts =
      length(
        for <<(b::1 <- <<trie_level_slice::bitstring-size(trie_level_slice_size)>>)>>, b > 0,
          do: b
      )

    do_as_trie(
      rest_trie,
      level_index + 1,
      j_children_counts,
      Trie.replace_at(accum, level_index, {j_nodes_curr_level, trie_level_slice}),
      rest_size
    )
  end
end
