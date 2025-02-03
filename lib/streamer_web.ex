defmodule StreamerWeb do
  def controller do
    quote do
      use Phoenix.Controller, namespace: StreamerWeb

      import Plug.Conn
      alias StreamerWeb.Router.Helpers, as: Routes
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
