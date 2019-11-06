defmodule TdHypermedia.Hypermedia do
  @moduledoc false

  alias Gettext.Interpolation
  import Canada.Can

  def build(path, conn, resource, resource_type \\ %{})

  def build(path, conn, resources, resource_type) when is_list(resources) do
    actions = build(path, conn, %{}, resource_type)
    resources = Enum.map(resources, &build(path, conn, &1))

    {resources, actions}
  end

  def build(path, conn, resource, resource_type) when resource_type == %{} do
    build_impl(path, conn, resource)
  end

  def build(path, conn, resource, resource_type) do
    build_impl(path, conn, resource, resource_type)
  end

  defp build_impl(path, conn, resource, resource_type \\ %{})

  defp build_impl(path, conn, %{__struct__: _} = resource, resource_type) do
    build_impl(path, conn, struct_to_map(resource), resource_type)
  end

  defp build_impl(path, conn, resource, resource_type) when resource == %{} do
    user = conn.assigns[:current_resource] || conn.assigns[:current_user]
    path
    |> build_actions(conn, resource_type, user)
    |> Enum.filter(&(&1.action != :index))
  end

  defp build_impl(path, conn, resource, _resource_type) do
    user = conn.assigns[:current_resource] || conn.assigns[:current_user]
    actions = build_actions(path, conn, hint(resource, path), user)
    {resource, actions}
  end

  defp build_actions(path, conn, resource, user) do
    resource = atomify(resource)

    conn
    |> get_routes
    |> Enum.filter(&(!is_nil(&1.helper)))
    |> Enum.filter(&route_by_path(path, &1))
    |> Enum.filter(&has_permission?(user, &1, resource))
    |> Enum.map(&interpolate(&1, resource))
    |> Enum.filter(&(&1.path != nil))
  end

  defp hint(%{} = resource, [head | _]), do: Map.put_new(resource, :hint, String.to_atom(head))

  defp hint(%{} = resource, path), do: Map.put_new(resource, :hint, String.to_atom(path))

  defp hint(resource, _path), do: resource

  defp route_by_path(path, %{path: route}) when is_list(path) do
    route
    |> String.split("/")
    |> Enum.any?(&(&1 in path))
  end

  defp route_by_path(path, %{path: route}) do
    route
    |> String.split("/")
    |> Enum.any?(&(&1 == path))
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

  defp interpolation(path, resource, regex, replacement) when is_map(resource) do
    path = Regex.replace(regex, path, replacement)

    case path
         |> Interpolation.to_interpolatable()
         |> Interpolation.interpolate(resource) do
      {:ok, route} -> route
      _ -> nil
    end
  end

  defp interpolation(_path, _resource, _regex, _replacement), do: nil

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

  defp atomify(resource) when is_map(resource) do
    Enum.into(resource, %{}, &atomify_pairs/1)
  end

  defp atomify(resource), do: resource

  defp atomify_pairs({key, value}) when is_binary(key), do: {String.to_atom(key), value}

  defp atomify_pairs(pair), do: pair
end
