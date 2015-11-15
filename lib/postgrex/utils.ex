defmodule Postgrex.Utils do
  @moduledoc false

  def error(error, %{state: :init}) do
    {:stop, error}
  end
  def error(error, s) do
    reply(error, s)
    {:stop, error, s}
  end

  def reply(reply, %{queue: queue}) do
    case :queue.out(queue) do
      {:empty, _queue} ->
        false
      {{:value, %{from: nil}}, _queue} ->
        false
      {{:value, %{from: from}}, _queue} when elem(reply, 0) == :error ->
        Connection.reply(from, reply)
        true
      {{:value, %{reply: :no_reply, from: from}}, _queue} ->
        Connection.reply(from, reply)
        true
      {{:value, %{reply: {:reply, reply}, from: from}}, _queue} ->
        Connection.reply(from, reply)
        true
    end
  end

  def reply(reply, {_, _} = from) do
    Connection.reply(from, reply)
    true
  end

  @doc """
  Converts pg major.minor.patch (http://www.postgresql.org/support/versioning) version to an integer
  """
  def parse_version(version) do
    list =
      version
      |> String.split(".")
      |> Enum.map(&elem(Integer.parse(&1), 0))

    case list do
      [major, minor, patch] -> {major, minor, patch}
      [major, minor] -> {major, minor, 0}
      [major] -> {major, 0, 0}
    end
  end
end
