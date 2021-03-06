defmodule TdHypermedia.ViewHelper do
  @moduledoc false

  import Phoenix.View

  alias TdHypermedia.Link

  @doc """
  Render a `hypermedia` collection with a given `view` and `template`
  (see [Phoenix.View](https://hexdocs.pm/phoenix/Phoenix.View.html)).

  `hypermedia` is a map containing the following keys:

    * `:collection_hypermedia` - a list of actions on the collection
    * `:collection` - a list of tuples {resource, resource_actions}
  """
  def render_many_hypermedia(hypermedia, view, template, assigns \\ %{}) do
    %{collection_hypermedia: collection_hypermedia, collection: collection} = hypermedia

    Map.merge(
      render_hypermedia(collection_hypermedia),
      %{"data" => render_many_hypermedia_element(collection, view, template, assigns)}
    )
  end

  def render_one_hypermedia(resource, hypermedia, view, template, assigns \\ %{}) do
    Map.merge(
      render_hypermedia(hypermedia),
      %{"data" => render_one(resource, view, template, assigns)}
    )
  end

  defp render_many_hypermedia_element(collection, view, template, assigns) do
    collection
    |> Enum.map(fn {resource, actions} -> Map.merge(render_hypermedia(actions), resource) end)
    |> Enum.map(fn resource -> render_one(resource, view, template, assigns) end)
  end

  defp render_hypermedia(hypermedia) do
    %{"_actions" => Enum.into(Enum.map(hypermedia, &render_link/1), %{})}
  end

  defp render_link(%Link{} = link) do
    {map_action(link.action),
     %{
       "href" => link.path,
       "method" => String.upcase(Atom.to_string(link.method)),
       "input" => input_map(link.schema)
     }}
  end

  defp render_link(map) do
    [{nested, hypermedia}] = Map.to_list(map)
    {String.to_atom(nested), Enum.into(Enum.map(hypermedia, &render_link/1), %{})}
  end

  defp map_action("show"), do: "ref"
  defp map_action("index"), do: "ref"
  defp map_action(other), do: other

  defp input_map(_schema) do
    %{}
  end

  def add_embedded_resources(resource, %{"_embedded" => embedded}) do
    Map.put(resource, "_embedded", embedded)
  end

  def add_embedded_resources(resource, _), do: resource
end
