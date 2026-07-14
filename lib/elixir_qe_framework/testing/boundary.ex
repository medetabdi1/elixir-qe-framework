defmodule ElixirQeFramework.Testing.Boundary do
  @moduledoc """
  Contract-style helpers for service-boundary assertions.

  Encode the "shape" of a successful/error response so integration tests fail
  loudly on schema drift instead of silently accepting wrong shapes.
  """

  @doc "Asserts `{:ok, value}` and returns value, or flunks with context."
  @spec unwrap_ok!(term(), String.t()) :: term()
  def unwrap_ok!({:ok, value}, _context), do: value

  def unwrap_ok!(other, context) do
    raise "expected {:ok, _} for #{context}, got: #{inspect(other)}"
  end

  @doc "Asserts `{:error, reason}` matches an expected atom reason."
  @spec assert_error!(term(), atom()) :: :ok
  def assert_error!({:error, reason}, expected) when reason == expected, do: :ok

  def assert_error!(other, expected) do
    raise "expected {:error, #{inspect(expected)}}, got: #{inspect(other)}"
  end

  @doc """
  Validates a map against required keys and optional type predicates.

      assert_contract!(payload, [:id, :status], %{status: &is_atom/1})
  """
  @spec assert_contract!(map(), [atom()], map()) :: :ok
  def assert_contract!(data, required_keys, predicates \\ %{})
      when is_map(data) and is_list(required_keys) and is_map(predicates) do
    missing = Enum.reject(required_keys, &Map.has_key?(data, &1))

    if missing != [] do
      raise "contract missing keys: #{inspect(missing)} in #{inspect(data)}"
    end

    Enum.each(predicates, fn {key, pred} ->
      value = Map.fetch!(data, key)

      unless pred.(value) do
        raise "contract predicate failed for #{inspect(key)}=#{inspect(value)}"
      end
    end)

    :ok
  end

  @doc "Converts an appointment struct into a boundary payload map."
  @spec appointment_payload(ElixirQeFramework.Appointment.t()) :: map()
  def appointment_payload(%ElixirQeFramework.Appointment{} = appt) do
    %{
      id: appt.id,
      client_name: appt.client_name,
      service: appt.service,
      starts_at: appt.starts_at,
      duration_minutes: appt.duration_minutes,
      status: appt.status
    }
  end

  @doc """
  Round-trips a payload through JSON to catch atom/string key drift —
  same class of bug API clients hit in the wild.
  """
  @spec assert_json_roundtrip!(map()) :: map()
  def assert_json_roundtrip!(payload) when is_map(payload) do
    decoded =
      payload
      |> json_safe()
      |> Jason.encode!()
      |> Jason.decode!()

    unless is_map(decoded) do
      raise "json roundtrip did not produce a map: #{inspect(decoded)}"
    end

    decoded
  end

  defp json_safe(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp json_safe(%MapSet{} = set), do: MapSet.to_list(set) |> json_safe()

  defp json_safe(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, json_safe(v)} end)
  end

  defp json_safe(list) when is_list(list), do: Enum.map(list, &json_safe/1)
  defp json_safe(other), do: other
end
