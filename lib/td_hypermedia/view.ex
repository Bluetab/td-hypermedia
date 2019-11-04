defmodule TdHypermedia.View do
  @moduledoc false

  @doc """
  Render a `hypermedia` collection with a given some resources and an assign key
  """
  def render_view({resources, actions}, assing_key) when is_list(resources) do
    Map.new()
    |> Map.put(assing_key, Enum.map(resources, &render_view/1))
    |> Map.merge(render(actions))
  end

  def render_view(resource, assing_key) do
    Map.put(Map.new(), assing_key, render_view(resource))
  end

  def render_view({resource, actions}) do
    Map.merge(resource, render(actions))
  end

  def render(actions) do
    %{_actions: Enum.into(actions, %{}, &render_link/1)}
  end

  def add_embedded_resources(resource, assigns) do
    actions = Map.take(assigns, [:_embedded])
    Map.merge(resource, actions)
  end

  def with_actions(struct, assigns) do
    actions = Map.take(assigns, [:_actions])
    Map.merge(struct, actions)
  end

  defp render_link(%{action: action, path: path, method: method, schema: schema}) do
    {map_action(action),
     %{
       href: path,
       method: String.upcase(Atom.to_string(method)),
       input: input_map(schema)
     }}
  end

  defp render_link(map) do
    [{nested, hypermedia}] = Map.to_list(map)
    {String.to_atom(nested), Enum.into(hypermedia, %{}, &render_link/1)}
  end

  defp map_action("show"), do: "ref"
  defp map_action("index"), do: "ref"
  defp map_action(other), do: other

  defp input_map(_schema) do
    %{}
  end
end
