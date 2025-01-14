defmodule Json5RustlerBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :json5_rustler_backend,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.32"},
      {:json5, "~> 0.3"},
      {:decimal, "~> 2.0"}
    ]
  end
end
