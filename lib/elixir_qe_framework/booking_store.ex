defmodule ElixirQeFramework.BookingStore do
  @moduledoc """
  In-memory booking store used as a service boundary for integration tests.

  Simulates a scheduling repository without Ecto so the sample stays dependency-light
  while still exercising process ownership and isolation patterns.
  """

  use GenServer

  alias ElixirQeFramework.Appointment

  # —— Public API ——

  def start_link(initial \\ %{}) do
    GenServer.start_link(__MODULE__, initial, name: __MODULE__)
  end

  @spec put(Appointment.t()) :: :ok | {:error, :conflict}
  def put(%Appointment{} = appt), do: GenServer.call(__MODULE__, {:put, appt})

  @spec get(String.t()) :: Appointment.t() | nil
  def get(id), do: GenServer.call(__MODULE__, {:get, id})

  @spec all() :: [Appointment.t()]
  def all, do: GenServer.call(__MODULE__, :all)

  @spec clear() :: :ok
  def clear, do: GenServer.call(__MODULE__, :clear)

  @spec count() :: non_neg_integer()
  def count, do: GenServer.call(__MODULE__, :count)

  # —— Callbacks ——

  @impl true
  def init(initial) when is_map(initial), do: {:ok, initial}

  @impl true
  def handle_call({:put, %Appointment{} = appt}, _from, state) do
    conflicts =
      state
      |> Map.values()
      |> Enum.filter(fn existing ->
        existing.id != appt.id and existing.status in [:pending, :confirmed] and
          Appointment.overlaps?(appt, existing)
      end)

    case conflicts do
      [] -> {:reply, :ok, Map.put(state, appt.id, appt)}
      _ -> {:reply, {:error, :conflict}, state}
    end
  end

  def handle_call({:get, id}, _from, state), do: {:reply, Map.get(state, id), state}
  def handle_call(:all, _from, state), do: {:reply, Map.values(state), state}
  def handle_call(:clear, _from, _state), do: {:reply, :ok, %{}}
  def handle_call(:count, _from, state), do: {:reply, map_size(state), state}
end
