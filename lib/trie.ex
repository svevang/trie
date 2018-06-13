defmodule Trie do
  @moduledoc """
  Trie CRUD.
  """

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

  def do_from_key(input_key, acc \\ [])

  # done recursing
  def do_from_key(input_key, acc) when bit_size(input_key) == 0 do
    Enum.reverse(acc)
  end

  def do_from_key(input_key, acc) do
    <<target_bit::size(1), rest::bitstring>> = input_key

    acc = case target_bit do
      1 -> [right_branch | acc]
      0 -> [left_branch | acc]
    end

    do_from_key(rest, acc)
  end

  def as_list(trie) do
    trie
    |> Enum.map(fn(bits)-> for <<b :: 1 <- bits  >>, do: b end)
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
