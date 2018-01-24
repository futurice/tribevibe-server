defmodule TribevibeWeb.VibeView do
  use TribevibeWeb, :view
  alias TribevibeWeb.DashboardView
  alias TribevibeWeb.GroupView

  def render("dashboard.json", %{dashboard: dashboard}) do
    render_one(dashboard, DashboardView, "dashboard.json")
  end

  def render("groups.json", %{groups: groups}) do
    render_many(groups, GroupView, "group.json")
  end

  def render("feedbacks.json", %{feedbacks: feedbacks}) do
    render_many(feedbacks, DashboardView, "feedback.json")
  end
end
