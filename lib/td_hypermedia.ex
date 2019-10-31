defmodule Plug.TdHypermedia do
  @moduledoc false
  alias TdHypermedia.Hypermedia
  alias TdHypermedia.View

  def put_hypermedia(conn, path, assigns) do
    resource_type = Keyword.get(assigns, :resource_type, [])
    {assign_key, resources} = find_resources(assigns)

    rendered = render_hypermedia(path, conn, resources, resource_type, assign_key)
    assigns = update_assigns_values(assigns, rendered)

    Map.update!(conn, :assigns, &Map.merge(&1, assigns))
  end

  defp find_resources(assigns) do
    assign_key = 
      assigns
      |> Keyword.keys()
      |> hd()
    
    {assign_key, Keyword.get(assigns, assign_key)}
  end

  defp render_hypermedia(path, conn, resources, resource_type, assign_key) do
    path
    |> build_hypermedia(conn, resources, resource_type)
    |> View.render_view(assign_key)
  end

  defp build_hypermedia(path, conn, resources, resource_type) do
    Hypermedia.build(path, conn, resources, resource_type)
  end
  
  defp update_assigns_values(assigns, rendered) do
    assigns 
    |> Keyword.delete(:resource_type)
    |> Enum.into(%{}) 
    |> Map.merge(rendered)
  end
end
