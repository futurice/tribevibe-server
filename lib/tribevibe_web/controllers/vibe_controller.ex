defmodule TribevibeWeb.VibeController do
  use TribevibeWeb, :controller
  use PhoenixSwagger
  alias Tribevibe.Core

  action_fallback TribevibeWeb.FallbackController

  ### CONTROLLER ###

  swagger_path :dashboard_all do
    get "/api/dashboard"
    description "Dashboard for all company values"
    response 200, "OK", Schema.ref(:Dashboard)
  end
  def dashboard_all(conn, _params) do
    engagements = Core.fetch_tribe_engagements()
    %{metrics: metrics, engagement: engagement} = Core.fetch_metrics()
    feedbacks = Core.fetch_newest_feedbacks()

    render(conn, "dashboard.json", dashboard: %{
      feedbacks: feedbacks,
      metrics: metrics,
      engagement: engagement,
      engagements: engagements})
  end

  swagger_path :dashboard_group do
    get "/api/dashboard/{group}"
    description "Dashboard for single group"
    parameter :group, :path, :string, "Group name", required: true, example: "Tammerforce"
    response 200, "OK", Schema.ref(:Dashboard)
  end
  def dashboard_group(conn, %{"group" => group}) do
    engagements = Core.fetch_tribe_engagements()
    feedbacks = Core.fetch_newest_feedbacks(group)
    %{metrics: metrics, engagement: engagement} = Core.fetch_metrics(group)

    render(conn, "dashboard.json", dashboard: %{
      feedbacks: feedbacks,
      metrics: metrics,
      engagement: engagement,
      engagements: engagements})
  end

  swagger_path :groups do
    get "/api/groups"
    description "Groups"
    response 200, "OK", Schema.ref(:Groups)
  end
  def groups(conn, _params) do
    groups = Core.fetch_groups()

    render(conn, "groups.json", groups: groups)
  end

  swagger_path :feedback do
    get "/api/feedback"
    description "Newest feedbacks"
    response 200, "OK", Schema.ref(:FeedbackBlock)
  end
  def feedback(conn, _params) do
    feedbacks = Core.fetch_newest_feedbacks()

    render(conn, "feedbacks.json", feedbacks: feedbacks)
  end

  swagger_path :feedback_group do
    get "/api/feedback/{group}"
    description "Newest feedbacks for given group"
    parameter :group, :path, :string, "Group name", required: true, example: "Tammerforce"
    response 200, "OK", Schema.ref(:FeedbackBlock)
  end
  def feedback_group(conn, %{"group" => group}) do
    feedbacks = Core.fetch_newest_feedbacks(group)

    render(conn, "feedbacks.json", feedbacks: feedbacks)
  end

  swagger_path :engagement do
    get "/api/engagement"
    description "Engagement"
    response 200, "OK", Schema.ref(:Engagements)
  end
  def engagement(conn, _params) do
    engagements = Core.fetch_tribe_engagements()

    render(conn, "engagements.json", engagements: engagements)
  end

  def swagger_definitions do
    %{
      Reply: swagger_schema do
        title "Reply"
        description "A single feedback question"
        properties do
          dateCreated :string, "Timestamp of reply", format: "ISO-8601"
          message :string, "Reply message"
          isOriginalPoster :boolean, "Is the message by the original poster or someone else?"
        end
      end,
      Replies: swagger_schema do
        title "Replies"
        description "A collection feedback replies"
        type :array
        items Schema.ref(:Reply)
      end,
      Tags: swagger_schema do
        title "Tags"
        description "A collection feedback tags"
        type :array
        items %{
          type: :string
        }
      end,
      Values: swagger_schema do
        title "Values"
        description "A collection metric values"
        type :array
        items Schema.ref(:Value)
      end,
      Value: swagger_schema do
        title "Value"
        description "A single metric value"
        properties do
          value :number, "Tribe engagement amount, 0.0 - 10.0"
          date :string, "Date string, YYYY-MM-DD"
        end
        example %{
          value: 9.8,
          date: "2018-01-01"
        }
      end,
      Engagement: swagger_schema do
        title "Engagement"
        description "A single engagement statistic"
        properties do
          name :string, "Tribe name"
          value :number, "Tribe engagement amount, 0.0 - 10.0"
        end
        example %{
          name: "Tammerforce",
          value: 9.8
        }
      end,
      Engagements: swagger_schema do
        title "Engagements"
        description "A collection engagements of each tribe"
        type :array
        items Schema.ref(:Engagement)
      end,
      Metric: swagger_schema do
        title "Metric"
        description "A single metric statistic"
        properties do
          id :string, "ID of a metric"
          name :string, "Display name of the metric"
          values Schema.ref(:Values), "Weekly metric values"
        end
        example %{
          values: [
            %{value: 7.2, date: "2018-01-01"},
            %{value: 7.2, date: "2018-01-08"},
            %{value: 7.2, date: "2018-01-15"}
          ],
          name: "Happiness",
          id: "MG-7"
        }
      end,
      Metrics: swagger_schema do
        title "Metrics"
        description "A collection metrics"
        type :array
        items Schema.ref(:Metric)
      end,
      Feedback: swagger_schema do
        title "Feedback"
        description "A single feedback question"
        properties do
          dateCreated :string, "Timestamp of feedback question", format: "ISO-8601"
          question :string, "Text of the feedback question"
          answer :string, "Text of feedback answer"
          tags Schema.ref(:Tags), "Feedback tags"
          replies Schema.ref(:Replies), "Feedback replies"
        end
        example %{
          dateCreated: "2018-01-02T17:01:10.985007Z",
          question: "What kind of support would you like to receive to help you deal with stress at work?",
          answer: "More discussions about work related stress in peer-groups, also senior coaching.",
          tags: [
            "Constructive", "Wellness"
          ],
          replies: [
            %{
              dateCreated: "2018-01-23",
              message: "Thank you for your thought! This is something we should definitely improve.",
              isOriginalPoster: false
            }
          ]
        }
      end,
      Feedbacks: swagger_schema do
        title "Feedbacks"
        description "A collection feedbacks"
        type :array
        items Schema.ref(:Feedback)
      end,
      FeedbackBlock: swagger_schema do
        title "FeedbackBlock"
        description "Block containting positive and constructive feedback"
        properties do
          positive Schema.ref(:Feedbacks), "Newest #public feedbacks tagged Positive."
          constructive Schema.ref(:Feedbacks), "Newest #public feedbacks tagged Constructive."
          poll_feedback Schema.ref(:Feedbacks), "Newest #public feedbacks tagged Poll Feedback."
        end
      end,
      Dashboard: swagger_schema do
        title "Dashboard"
        description "Dashboard displaying random feedback and metrics"
        properties do
          engagements Schema.ref(:Engagements), "Current tribe engagement levels"
          engagement Schema.ref(:Metric), "Weekly engagement levels for selected tribe or all company"
          metrics Schema.ref(:Metrics), "Weekly metrics"
          feedbacks Schema.ref(:FeedbackBlock), "Newest feedbacks."
        end
      end,
      Groups: swagger_schema do
        title "Groups"
        description "A collection groupsNames"
        type :array
        items %{
          type: :string
        }
        example [
          "Tammerforce", "Avalon", "Stockholm"
        ]
      end
    }
  end
end
