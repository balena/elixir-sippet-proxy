defmodule Sippet.Proxy.Registry do
  @moduledoc """
  The Proxy registry, where client and server transaction keys are associated
  to controller processes.
  """

  @type client_key :: Sippet.Transactions.Client.Key.t

  @type server_key :: Sippet.Transactions.Server.Key.t

  @doc """
  Starts the proxy registry as a supervisor process.

  Manually it can be started as:

      Sippet.Proxy.Registry.start_link()

  In your supervisor tree, you would write:

      supervisor(Sippet.Proxy.Registry, [])

  The registry is partitioned according to the number of schedulers available.
  """
  def start_link() do
    args = [partitions: System.schedulers_online()]
    Registry.start_link(:unique, __MODULE__, args)
  end

  @doc """
  Takes a `{:via, Registry, {registry, key}}` tuple corresponding to this
  registry for the given `key`.

  XXX: transform into a `start_child`.
  """
  @spec via_tuple(client_key | server_key) ::
        {:via, Registry, {__MODULE__, client_key | server_key}}
  def via_tuple(%Sippet.Transactions.Client.Key{} = client_key),
    do: do_via_tuple(client_key)

  def via_tuple(%Sippet.Transactions.Server.Key{} = server_key),
    do: do_via_tuple(server_key)

  defp do_via_tuple(key), do: {:via, Registry, {__MODULE__, key}}

  @doc """
  Looks up if a registered process exists to handle the given key.

  An empty list if there is no match.
  """
  @spec lookup(client_key | server_key) :: pid | nil
  def lookup(%Sippet.Transactions.Client.Key{} = client_key),
    do: do_lookup(client_key)

  def lookup(%Sippet.Transactions.Server.Key{} = server_key),
    do: do_lookup(server_key)

  defp do_lookup(key) do
    case Registry.lookup(__MODULE__, key) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  @doc """
  Registers the current process under the given client or server transaction
  key in the proxy registry.

  By doing so, incoming requests or responses will be redirected to the current
  process once they come. The registry is cleared once the process finishes.
  """
  @spec register_alias(client_key | server_key) ::
        {:ok, pid} | {:error, {:already_registered, pid}}
  def register_alias(client_or_server_key)

  def register_alias(%Sippet.Transactions.Client.Key{} = client_key),
    do: do_register_alias(client_key)

  def register_alias(%Sippet.Transactions.Server.Key{} = server_key),
    do: do_register_alias(server_key)

  defp do_register_alias(key),
    do: Registry.register(__MODULE__, key, nil)

  @doc """
  Unregisters the process registered under the given client or server
  transaction key.
  """
  @spec unregister_alias(client_key | server_key) :: :ok
  def unregister_alias(client_or_server_key)

  def unregister_alias(%Sippet.Transactions.Client.Key{} = client_key),
    do: do_unregister_alias(client_key)

  def unregister_alias(%Sippet.Transactions.Server.Key{} = server_key),
    do: do_unregister_alias(server_key)

  defp do_unregister_alias(key),
    do: Registry.unregister(__MODULE__, key)

  @doc """
  Returns all client or server keys associated with the given process.
  """
  @spec aliases(pid) :: [client_key | server_key]
  def aliases(pid), do: Registry.keys(__MODULE__, pid)
end
