defmodule TdHypermedia.Hypermedia do
  @moduledoc false

  alias Gettext.Interpolation
  import Canada.Can

  def build(helper, conn, resource, resource_type \\ [])

  def build(helper, conn, resources, resource_type) when is_list(resources) do
    actions = build(helper, conn, %{}, resource_type)
    resources = Enum.map(resources, &build(helper, conn, &1))

    {resources, actions}
  end

  def build(helper, conn, resource, [h | t]) do
    build(helper, conn, resource, t) ++ [%{h => build_impl(h, conn, resource)}]
  end

  def build(helper, conn, resource, []) do
    build_impl(helper, conn, resource)
  end

  def build(helper, conn, resource, resource_type) do
    build_impl(helper, conn, resource, resource_type)
  end

  defp build_impl(helper, conn, resource, resource_type \\ %{})

  defp build_impl(helper, conn, %{__struct__: _} = resource, resource_type) do
    build_impl(helper, conn, struct_to_map(resource), resource_type)
  end

  defp build_impl(helper, conn, resource, resource_type) when resource == %{} do
    current_resource = conn.assigns[:current_resource] || conn.assigns[:current_user]
    build_actions(helper, conn, resource_type, current_resource)
  end

  defp build_impl(helper, conn, resource, _resource_type) do
    current_resource = conn.assigns[:current_resource] || conn.assigns[:current_user]
    
    actions = 
      helper
      |> build_actions(conn, resource, current_resource)
      |> Enum.filter(&(&1.action != :index and &1.action != :create))
    
    {resource, actions}
  end

  defp build_actions(helper, conn, target, current_resource) do
    conn
    |> get_routes
    |> Enum.filter(&(!is_nil(&1.helper)))
    |> Enum.filter(&(&1.helper == helper))
    |> Enum.filter(&has_permission?(current_resource, &1, target))
    |> Enum.map(&interpolate(&1, target))
    |> Enum.filter(&(&1.path != nil))
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
      r -> r.__routes__
    end
  end

  defp interpolate(%{plug_opts: action, path: path, verb: verb} = _route, resource) do
    interpolate(path, action, verb, resource)
  end

  defp interpolate(%{opts: action, path: path, verb: verb} = _route, resource) do
    interpolate(path, action, verb, resource)
  end

  defp interpolate(path, action, verb, resource) do
    %{
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

    case path
         |> Interpolation.to_interpolatable()
         |> Interpolation.interpolate(resource) do
      {:ok, route} -> route
      _ -> nil
    end
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
