defmodule TribevibeWeb.DashboardView do
  use TribevibeWeb, :view
  alias TribevibeWeb.DashboardView

  def render("reply.json", %{dashboard: reply}) do
    %{dateCreated: reply["creationDate"],
      message: reply["message"]}
  end

  def render("dashboard.json", %{dashboard: dashboard}) do
    %{metrics: dashboard.metrics,
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
end
