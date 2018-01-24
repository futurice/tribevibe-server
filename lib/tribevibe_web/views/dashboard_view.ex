defmodule TribevibeWeb.DashboardView do
  use TribevibeWeb, :view
  alias TribevibeWeb.DashboardView

  def render("reply.json", %{dashboard: reply}) do
    %{dateCreated: reply["creationDate"],
      message: reply["message"]}
  end

  def render("dashboard.json", %{dashboard: dashboard}) do
    %{engagements: render_many(dashboard.engagements, DashboardView, "engagement.json"),
      metrics: dashboard.metrics,
      feedback: render_one(dashboard.feedback, DashboardView, "feedback.json")
    }
  end

  def render("feedback.json", %{dashboard: feedback}) do
    %{dateCreated: feedback["creationDate"],
      question: feedback["questionAsked"],
      answer: feedback["message"],
      tags: feedback["tags"],
      replies: render_many(feedback["replies"], DashboardView, "reply.json")
    }
  end

  def render("engagement.json", %{dashboard: engagement}) do
    %{name: engagement.name,
      value: engagement.value}
  end
end
