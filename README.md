# Trie

This is an implementation of a binary pointerless [trie](https://en.wikipedia.org/wiki/Trie). Based on _Trie
Methods for Text and Spatial Data on Secondary Storage_ [Shang 2001], .
Secifically, this is a _FuTrie_ which is "a binary tree whose nodes do not
store information and whose links are labeled 0 for left and 1 for
right". So, the value of each bit in the key determines the path of the
tree traversal.

# Usage

Create the trie using a list of
[elixir binaries](https://elixir-lang.org/getting-started/binaries-strings-and-char-lists.html#binaries):
```
iex> trie = ["A","Aaronic", "Aaronical", "Aaronite", "Aaronitic"] |> Trie.from_keys
```

Examine all the keys in the trie:
```
iex> trie |> Trie.all_keys
["Aaronical", "Aaronite", "Aaronitic"]
```

Perform a prefix search:
```
iex> trie |> Trie.prefix_search("Aaronit")
["Aaronite", "Aaronitic"]
```


# Discussion

The input keys are a sequences of bits.  When appending a key, we can follow the
left and right branches (0 and 1) of the bitstring key, keeping track of the jth
node index at that level in the tree -- how 'wide' the tree is at depth
i for any key.

When adding a key bifurcates, or splits, from the current tree structure
at some depth i, then a new nodes at that depth in the tree is
added to support the new branch.

Because the keys overlap in some cases, the subset keys are 'absorbed' into the
larger super set keys (as in the case of `Aar` and `Aaronic`).


## Installation

The package can be installed by adding `trie` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:trie, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/trie](https://hexdocs.pm/trie).

