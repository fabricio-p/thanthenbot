[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/seeds.exs"
  ],
  line_length: 80,
  locals_without_parens: [
    def: 2,
    defp: 2,
    defmacro: 2,
    defmacrop: 2,
    defmodule: 2
  ]
]
