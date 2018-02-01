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
    %{
      positive: render_many(feedbacks.positive, VibeView, "feedback.json"),
      constructive: render_many(feedbacks.constructive, VibeView, "feedback.json")
    }
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
      engagement: dashboard.engagement,
      metrics: dashboard.metrics,
      feedbacks: %{
        positive: render_many(dashboard.feedbacks.positive, VibeView, "feedback.json"),
        constructive: render_many(dashboard.feedbacks.constructive, VibeView, "feedback.json")
      }
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
