## Elixir in Action - Chapter 5: Stateful Server Processes

# To run, $ iex
# iex > c("todo_server.ex")
# iex > server_pid = TodoServer.start()

# Manages client and server process communication
defmodule TodoServer do
  def start() do
    spawn(fn -> loop(TodoList.new()) end)
  end

  defp loop(entries) do
    new_entries = receive do
      message -> process_message(entries, message)
    end
    loop(new_entries)
  end

  def add_entry(todo_server_pid, entry = %{date: {_y, _m, _d}, title: _title}) do
    send(todo_server_pid, {:add_entry, entry})
  end

  def entries(todo_server_pid, date = {_y, _m, _d}) do
    send(todo_server_pid, {:entries, date, self()})
    receive do
      {:response, value} -> value
    after 5000 ->
      {:error, :timeout}
    end
  end

  defp process_message(entries, {:add_entry, new_entry}) do
    TodoList.add_entry(entries, new_entry)
  end

  defp process_message(entries, {:entries, date, caller_pid}) do
    send(caller_pid, {:response, TodoList.entries(entries, date)})

     # this function should not modify state, so old state returned
    entries
  end
end

# Keeps logic separate from process communication
defmodule TodoList do
  def new() do
    []
  end

  def add_entry(entries, entry) do
    [entry | entries]
  end

  def entries(entries, date) do
    Enum.filter(entries, fn entry -> entry.date == date end)
  end
end
