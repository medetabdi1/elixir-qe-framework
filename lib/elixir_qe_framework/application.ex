defmodule ElixirQeFramework.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {ElixirQeFramework.BookingStore, name: ElixirQeFramework.BookingStore}
    ]

    opts = [strategy: :one_for_one, name: ElixirQeFramework.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
