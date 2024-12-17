defmodule TdHypermedia.ControllerHelper do
  @moduledoc false

  alias Gettext.Interpolation.Default
  alias TdHypermedia.Collection
  alias TdHypermedia.Link

  import Canada.Can

  def collection_hypermedia(helper, conn, resource, resource_type) do
    %Collection{
      collection_hypermedia: hypermedia(helper, conn, %{}, resource_type),
      collection: Enum.map(resource, &{&1, hypermedia(helper, conn, &1, [])})
    }
  end

  def hypermedia(helper, conn, resource, nested \\ [])

  def hypermedia(helper, conn, resource, nested) when is_list(resource) do
    %Collection{
      collection_hypermedia: hypermedia(helper, conn, %{}),
      collection:
        Enum.into(
          Enum.map(resource, &{&1, hypermedia(helper, conn, &1, nested)}),
          %{}
        )
    }
  end

  def hypermedia(helper, conn, resource, [h | t]) do
    hypermedia(helper, conn, resource, t) ++ [%{h => hypermedia_nested(h, conn, resource)}]
  end

  def hypermedia(helper, conn, resource, []) do
    hypermedia_impl(helper, conn, resource)
  end

  def hypermedia(helper, conn, resource, resource_type) do
    hypermedia_impl(helper, conn, resource, resource_type)
  end

  defp hypermedia_impl(helper, conn, %{}, resource_type) do
    current_resource = conn.assigns[:current_resource] || conn.assigns[:current_user]

    conn
    |> get_routes()
    |> Enum.reject(&is_nil(&1.helper))
    |> Enum.filter(
      &(String.starts_with?(&1.helper, helper) and
          has_permission?(current_resource, &1, resource_type))
    )
    |> Enum.map(&interpolate(&1, resource_type))
    |> Enum.filter(&(&1.path != nil))
  end

  defp hypermedia_impl(helper, conn, resource)

  defp hypermedia_impl(helper, conn, resource) do
    current_resource = conn.assigns[:current_resource] || conn.assigns[:current_user]

    conn
    |> get_routes
    |> Enum.reject(&is_nil(&1.helper))
    |> Enum.filter(
      &(String.starts_with?(&1.helper, helper) and has_permission?(current_resource, &1, resource))
    )
    |> Enum.map(&interpolate(&1, resource))
    |> Enum.reject(&is_nil(&1.path))
    |> Enum.filter(&(resource == %{} or (&1.action != "index" and &1.action != "create")))
  end

  defp has_permission?(current_resource, %{opts: opts}, resource) do
    can?(current_resource, opts, resource)
  end

  defp has_permission?(current_resource, %{plug_opts: opts}, resource) do
    can?(current_resource, opts, resource)
  end

  defp get_routes(%{private: private} = _conn) do
    router =
      private
      |> Map.keys()
      |> Enum.find(&String.ends_with?(Atom.to_string(&1), "Router"))

    case router do
      nil -> []
      r -> r.__routes__()
    end
  end

  defp interpolate(%{plug_opts: action, path: path, verb: verb} = _route, resource) do
    interpolate(path, action, verb, resource)
  end

  defp interpolate(%{opts: action, path: path, verb: verb} = _route, resource) do
    interpolate(path, action, verb, resource)
  end

  defp interpolate(path, action, verb, resource) do
    %Link{
      action: action,
      path: interpolation(path, resource, ~r/:(\w*id)/),
      method: verb,
      schema: %{}
    }
  end

  defp interpolation(path, resource, regex) do
    case Regex.scan(regex, path) do
      [] -> path
      [_id] -> interpolation(path, resource, regex, "%{id}")
      _ids -> interpolation(path, resource, regex, "%{\\1}")
    end
  end

  defp interpolation(path, resource, regex, replacement) do
    path = Regex.replace(regex, path, replacement)

    case Default.runtime_interpolate(path, resource) do
      {:ok, route} -> route
      _ -> nil
    end
  end

  defp hypermedia_nested(helper, conn, %{__struct__: _} = resource) do
    hypermedia_nested(helper, conn, struct_to_map(resource))
  end

  defp hypermedia_nested(helper, conn, resource) do
    current_user = conn.assigns[:current_user]

    conn
    |> get_routes
    |> Enum.filter(
      &(&1.helper == helper and &1.opts == :index and has_permission?(current_user, &1, resource))
    )
    |> Enum.map(&interpolate(&1, resource))
    |> Enum.filter(&(&1.path != nil))
  end

  defp struct_to_map(%{__struct__: name} = resource) do
    key =
      name
      |> Module.split()
      |> List.last()
      |> String.downcase()
      |> Kernel.<>("_id")
      |> String.to_atom()

    resource
    |> Map.from_struct()
    |> Map.put(key, resource.id)
  end
end
