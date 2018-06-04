defmodule Trie do
  @moduledoc """
  Trie CRUD.
  """

  @page_size 4096

  @doc """
  Hello world.

  ## Examples

  iex> {:ok, _file} = Trie.create_unsorted([], "/tmp/test.trie")
  iex> :ok
  :ok

  """

  def create_unsorted(key_list, dest) do
    {:ok, trie_file} = File.open(dest, [:write])
  end

end
