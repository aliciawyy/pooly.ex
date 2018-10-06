# Pooly.ex

This project implements a supervisor tree for Erlang process like the following

![supervisor tree](./docs/supervisor_tree.png)

Servers are used to maintain the states of supervisors at the same level.

## Other information

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pooly` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pooly, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/pooly](https://hexdocs.pm/pooly).
