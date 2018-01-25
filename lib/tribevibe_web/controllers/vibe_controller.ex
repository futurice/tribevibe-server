defmodule TribevibeWeb.VibeController do
  use TribevibeWeb, :controller
  use PhoenixSwagger
  alias Tribevibe.Core

  action_fallback TribevibeWeb.FallbackController

  def swagger_definitions do
    %{
      Reply: swagger_schema do
        title "Reply"
        description "A single feedback question"
        properties do
          dateCreated :string, "Timestamp of reply", format: "ISO-8601"
          message :string, "Reply message"
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
        items %{
          type: :number
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
          values: [ 7.2, 7.2, 7.2, 7.1, 7.3 ],
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
              message: "Thank you for your thought! This is something we should definitely improve. Are you interested to start meeting with your peers around this topic? It&#39;s true that already by sharing you feelings with others makes stress more tolerable. And one more question to you, by senior coaching do you mean more coaching for seniors or seniors to coach you?"
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
      Dashboard: swagger_schema do
        title "Dashboard"
        description "Dashboard displaying random feedback and metrics"
        properties do
          engagements Schema.ref(:Engagements), "Current tribe engagement levels"
          metrics Schema.ref(:Metrics), "Weekly metrics"
          feedback Schema.ref(:Feedback), "Random feedback"
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

  ### CONTROLLER ###

  swagger_path :dashboard_all do
    get "/api/dashboard"
    description "Dashboard for all company values"
    response 200, "OK", Schema.ref(:Dashboard)
  end
  def dashboard_all(conn, _params) do
    engagements = Core.fetch_tribe_engagements()
    metrics = Core.fetch_metrics()
    feedback = Core.fetch_random_feedback()

    render(conn, "dashboard.json", dashboard: %{
      feedbacks: [
        feedback,
        feedback
      ],
      metrics: metrics,
      engagements: engagements})
  end

  swagger_path :dashboard_group do
    get "/api/dashboard/{group}"
    description "Dashboard for single group"
    parameter :group, :path, :integer, "Group ID", required: true, example: 3
    response 200, "OK", Schema.ref(:Dashboard)
  end
  def dashboard_group(conn, %{"group" => group}) do
    engagements = Core.fetch_tribe_engagements([group])
    feedback = Core.fetch_random_feedback(group)
    metrics = Core.fetch_metrics(group)

    render(conn, "dashboard.json", dashboard: %{
      feedbacks: [
        feedback,
        feedback
      ],
      metrics: metrics,
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
    description "Feedbacks"
    response 200, "OK", Schema.ref(:Feedbacks)
  end
  def feedback(conn, _params) do
    feedbacks = Core.fetch_feedbacks

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
end
