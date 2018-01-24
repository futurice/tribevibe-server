defmodule TribevibeWeb.GroupView do
  use TribevibeWeb, :view

  def render("group.json", %{group: group}) do
    group
  end
end
