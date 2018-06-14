# Trie

A pointerless implementation of a Trie. Keys are appended to a binary
tree backed by block-based persistent storage. Initial support will
include trie creation, deletion and reads.

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

