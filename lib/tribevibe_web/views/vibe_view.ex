defmodule TribevibeWeb.VibeView do
  use TribevibeWeb, :view
  alias TribevibeWeb.VibeView

  def render("dashboard.json", %{dashboard: dashboard}) do
    render_one(dashboard, VibeView, "dashboard.json")
  end

  def render("groups.json", %{groups: groups}) do
    render_many(groups, VibeView, "group.json")
  end

  def render("feedbacks.json", %{feedbacks: feedbacks}) do
    render_many(feedbacks, VibeView, "feedback.json")
  end

  def render("engagements.json", %{engagements: engagements}) do
    render_many(engagements, VibeView, "engagement.json")
  end

  ### TODO - Move these into separate view files per context

  def render("group.json", %{vibe: group}) do
    group
  end

  def render("reply.json", %{vibe: reply}) do
    %{dateCreated: reply["creationDate"],
      message: reply["message"]}
  end

  def render("dashboard.json", %{vibe: dashboard}) do
    %{engagements: render_many(dashboard.engagements, VibeView, "engagement.json"),
      metrics: dashboard.metrics,
      feedbacks: render_many(dashboard.feedbacks, VibeView, "feedback.json")
    }
  end

  def render("feedback.json", %{vibe: feedback}) do
    %{dateCreated: feedback["creationDate"],
      question: feedback["questionAsked"],
      answer: feedback["message"],
      tags: feedback["tags"],
      replies: render_many(feedback["replies"], VibeView, "reply.json")
    }
  end

  def render("engagement.json", %{vibe: engagement}) do
    %{name: engagement.name,
      value: engagement.value}
  end
end
