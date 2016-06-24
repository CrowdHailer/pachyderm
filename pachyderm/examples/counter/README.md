# Counter

**Recording the state changes of a Simple Counter**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add counter to your list of dependencies in `mix.exs`:

        def deps do
          [{:counter, "~> 0.0.1"}]
        end

  2. Ensure counter is started before your application:

        def application do
          [applications: [:counter]]
        end
