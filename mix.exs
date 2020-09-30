defmodule GoveeSemaphore.MixProject do
  use Mix.Project

  def project do
    [
      app: :govee_semaphore,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {GoveeSemaphoreApplication, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      dep(:govee, :github),
      {:enum_type, github: "axelson/enum_type", branch: "conditionally-generate-ecto-types"},
      {:typed_struct, ">= 0.0.0"},
      {:phoenix_pubsub, "~> 2.0"}
    ]
  end

  defp dep(:govee, :github), do: {:govee, github: "axelson/govee"}
  defp dep(:govee, :path), do: {:govee, path: "~/dev/govee"}
end
