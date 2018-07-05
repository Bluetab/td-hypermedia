defmodule TdHypermedia do
  @moduledoc false
  def controller do
    quote do
      import TdHypermedia.ControllerHelper
    end
  end

  def view do
    quote do
      import TdHypermedia.ViewHelper
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
