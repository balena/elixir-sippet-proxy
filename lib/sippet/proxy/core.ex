defmodule Sippet.Proxy.Core do
  @moduledoc """
  The Sippet Proxy core module.

  In order to register this module in your solution, add to your `config.exs`:

      config :sippet, Sippet.Core, Sippet.Proxy.Core

  """

  use Sippet.Core

  import Supervisor.Spec

  alias Sippet.Message, as: Message
  alias Sippet.Message.RequestLine, as: RequestLine
  alias Sippet.Message.StatusLine, as: StatusLine
  alias Sippet.Transactions, as: Transactions
  alias Sippet.Proxy.Controller, as: Controller
  alias Sippet.Proxy, as: Proxy

  require Logger

  def start_link() do
    children = [
      worker(Proxy.Registry, []),
      supervisor(Controller.Supervisor, [])
    ]

    options = [
      strategy: :one_for_one,
      name: __MODULE__
    ]

    Supervisor.start_link(children, options)
  end

  @doc """
  Receives a new incoming request from a remote host, or ACK.

  If it is a request out of a server transaction like an `:ack`, then it is
  forwarded to `Sippet.Proxy.Controller.stateless_receive_request/1`. Otherwise
  the proxy registry is looked up: if a controller exists for handling this
  request, it is forwarded to it; otherwise a new controller is created.
  """
  def receive_request(request, server_key)

  def receive_request(
      %Message{start_line: %RequestLine{}} = request, nil) do
    # This will happen for ACKs sent for 200 OK.
    Controller.stateless_receive_request(request)
  end

  def receive_request(%Message{start_line: %RequestLine{}} = request,
                      %Transactions.Server.Key{} = server_key) do
    case Proxy.Registry.lookup(server_key) do
      nil ->
        # on the event of an incoming request with a non null server key,
        # start a new proxy controller.
        case Controller.Supervisor.start_child(request, server_key) do
          {:ok, pid} ->
            pid |> Controller.receive_request(request, server_key)

          {:ok, pid, _info} ->
            pid |> Controller.receive_request(request, server_key)

          {:error, reason} ->
            Logger.error fn ->
              "#{inspect self()} error starting child #{server_key}: " <>
              "#{inspect reason}"
            end
            {:error, reason}
        end

      pid ->
        pid |> Controller.receive_request(request, server_key)
    end
  end

  @doc """
  Receives a response for a sent request.

  If it is a response out of a client transaction like 200 OK retransmissions
  for `:invite` requests, `Sippet.Controller.stateless_receive_response/1` is
  called. Otherwise, if there is a controller registered for receiving it, the
  response is forwarded to the controller; otherwise a log message is dropped.
  """
  def receive_response(response, client_key)

  def receive_response(%Message{start_line: %StatusLine{}} = response,
      nil) do
    # this will happen for 200 OK retransmissions.
    Controller.stateless_receive_response(response)
  end

  def receive_response(%Message{start_line: %StatusLine{}} = response,
      %Transactions.Client.Key{} = client_key) do
    # it is expected that the controller creates aliases to the client
    # keys they create when forwarding requests.
    case Proxy.Registry.lookup(client_key) do
      nil ->
        Logger.warn fn ->
          "controller #{inspect client_key} not found, got #{inspect response}"
        end

      pid ->
        pid |> Controller.receive_response(response, client_key)
    end
  end

  @doc """
  Receives a transport error from the server or client transaction.

  If there is a controller registered for receiving it, the error is forwarded
  to the controller; otherwise a log message is dropped.
  """
  def receive_error(reason, key) do
    # same as above: the error will reach the controller either the key
    # identifier is of a client or server key.
    case Proxy.Registry.lookup(key) do
      nil ->
        Logger.warn fn ->
          "controller #{inspect key} not found, got #{inspect reason}"
        end

      pid ->
        pid |> Controller.receive_error(reason, key)
    end
  end
end
