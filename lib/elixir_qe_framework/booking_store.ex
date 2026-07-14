defmodule ElixirQeFramework.BookingStore do
  @moduledoc """
  In-memory booking store used as a service boundary for integration tests.

  ## Isolation (critical for async ExUnit)

  Production / app boot uses a **named** process (`BookingStore`).

  Tests should start an **anonymous** store via `start_supervised!/1` and bind it
  with `bind/1` so each test process gets its own GenServer — the ExUnit/Mox
  recommendation over clearing a shared global (a common flake root cause).
  """

  use GenServer

  alias ElixirQeFramework.Appointment

  @process_key :booking_store_server

  # —— Process binding (tests) ——

  @doc "Bind this process's BookingStore calls to `server` (pid or name)."
  @spec bind(GenServer.server()) :: :ok
  def bind(server) do
    Process.put(@process_key, server)
    :ok
  end

  @doc "Clear any process-local store binding."
  @spec unbind() :: :ok
  def unbind do
    Process.delete(@process_key)
    :ok
  end

  @doc "Server used by client API — process binding, else named store."
  @spec server() :: GenServer.server()
  def server, do: Process.get(@process_key) || __MODULE__

  # —— Child spec / lifecycle ——

  def child_spec(opts) do
    opts = normalize_opts(opts)

    %{
      id: Keyword.get(opts, :id) || Keyword.get(opts, :name) || __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  @doc """
  Starts the store.

  Options:
    * `:name` — registered name (default `__MODULE__` for app boot). Pass `nil` for anonymous.
    * `:initial` — initial state map
  """
  def start_link(opts \\ []) do
    opts = normalize_opts(opts)
    initial = Keyword.get(opts, :initial, %{})
    name = Keyword.get(opts, :name, __MODULE__)

    genserver_opts =
      case name do
        nil -> []
        name -> [name: name]
      end

    GenServer.start_link(__MODULE__, initial, genserver_opts)
  end

  # —— Public API (routed through `server/0`) ——

  @spec put(Appointment.t()) :: :ok | {:error, :conflict}
  def put(%Appointment{} = appt), do: GenServer.call(server(), {:put, appt})

  @spec get(String.t()) :: Appointment.t() | nil
  def get(id), do: GenServer.call(server(), {:get, id})

  @spec all() :: [Appointment.t()]
  def all, do: GenServer.call(server(), :all)

  @spec clear() :: :ok
  def clear, do: GenServer.call(server(), :clear)

  @spec count() :: non_neg_integer()
  def count, do: GenServer.call(server(), :count)

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

  defp normalize_opts(opts) when is_list(opts), do: opts
  # Support legacy `{BookingStore, %{}}` child specs
  defp normalize_opts(initial) when is_map(initial), do: [initial: initial, name: __MODULE__]
end
