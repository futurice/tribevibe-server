defmodule Tribevibe.Core do
  @moduledoc """
  The core functionality.
  """
  require Logger
  use Timex

  @metrics_whitelist [
    "MG-1", # Recognition
    "MG-2", # Feedback
    "MG-3", # Relationship with Colleagues
    "MG-4", # Relationship with Managers
    "MG-5", # Satisfaction
    "MG-6", # Alignement
    "MG-7", # Happiness
    "MG-8", # Wellness
    "MG-9", # Personal Growth
    "MG-10" # Ambassadorship
  ]

  @max_metrics_history months: -3
  @trial_end_date ~D[2018-01-01]

  @doc """
  Fetches list of groups from Officevibe API
  """
  def fetch_groups do
    url = "#{System.get_env("OFFICEVIBE_API_URL")}/v2/groups"
    token = System.get_env("OFFICEVIBE_API_TOKEN")
    headers = ["Authorization": "Bearer #{token}"]

    cache_key = url

    Cachex.get!(:officevibe_cache, cache_key, fallback: fn(_request_url) ->
      # Fallback to fetch data from OfficeVibe API
      case HTTPoison.get(url, headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          response = body
          |> Poison.decode!
          |> Map.get("data")
          |> Map.get("groups")
          |> Enum.map(fn(group) -> Map.get(group, "name") end)
          |> filter_subgroups

          { :commit, response }
        {:ok, %HTTPoison.Response{status_code: 404}} ->
          Logger.error("Failed to fetch groups")
          { :ignore, [] }
        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("API error with groups: #{inspect reason}")
          { :ignore, reason }
      end
    end)
  end

  # Removes any groups that have '>' in their name
  defp filter_subgroups(groups) do
    Enum.filter(groups, fn(group) -> !String.contains?(group, ">") end)
  end

  @doc """
  Fetches newest feedbacks from Officevibe API that match criteria
  - Constructive feedbacks which have been answered
  - Positive feedbacks by default (min. 20 characters)
  - 10 newest feedbacks of both categories
  - Must contain string '#public' somewhere in the original posters text body
  """
  def fetch_newest_feedbacks(groupName \\ nil) do
    url = "#{System.get_env("OFFICEVIBE_API_URL")}/v2/feedback"
    token = System.get_env("OFFICEVIBE_API_TOKEN")
    headers = ["Authorization": "Bearer #{token}"]
    options = [
      params: %{
        groupName: groupName,
        fromDate: Timex.shift(Timex.today, months: -1) |> Timex.format!("{ISOdate}")
      }
    ]

    cache_key = url <> "#" <> inspect options

    Cachex.get!(:officevibe_cache, cache_key, fallback: fn(_request_url) ->
      case HTTPoison.get(url, headers, options) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          feedbacks = body
          |> Poison.decode!
          |> Map.get("data")
          |> Map.get("conversations")

          positive = feedbacks
          |> filter_feedbacks_by_tag("Positive")
          |> filter_short_feedbacks
          |> filter_public_feedbacks
          |> mark_original_posters
          |> sort_by_newest
          |> Enum.take(10)

          constructive = feedbacks
          |> filter_feedbacks_by_tag("Constructive")
          |> filter_unreplied_feedbacks
          |> filter_public_feedbacks
          |> mark_original_posters
          |> sort_by_newest
          |> Enum.take(10)

          { :commit, %{positive: positive, constructive: constructive} }
        {:ok, %HTTPoison.Response{status_code: 404}} ->
          Logger.error("Failed to fetch feedbacks")
          { :ignore, %{positive: [], constructive: []} }
        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("API error with feedbacks: #{inspect reason}")
          { :ignore, reason }
      end
    end)
  end

  defp filter_feedbacks_by_tag(feedbacks, tag) do
    Enum.filter(feedbacks, fn(%{"tags" => tags}) -> Enum.member?(tags, tag) end)
  end

  defp filter_unreplied_feedbacks(feedbacks) do
    Enum.filter(feedbacks, fn(%{"replies" => replies}) -> !Enum.empty?(replies) end)
  end

  defp filter_short_feedbacks(feedbacks, min_characters \\ 20) do
    Enum.filter(feedbacks, fn(%{"message" => message}) -> String.length(message) >= min_characters end)
  end

  defp filter_public_feedbacks(feedbacks) do
    Enum.filter(feedbacks, fn(%{"replies" => replies, "userEmail" => originalEmail} = feedback) ->
      is_public?(feedback) || Enum.any?(replies, fn(reply) ->
        is_public?(reply) && is_original_poster?(reply, originalEmail)
      end)
    end)
  end

  defp sort_by_newest(feedbacks) do
    Enum.sort_by(feedbacks, &(Map.get(&1, "creationDate")), &>=/2)
  end

  defp mark_original_posters(feedbacks) do
    Enum.map(feedbacks, fn(%{"replies" => replies, "userEmail" => originalEmail} = feedback) ->
      Map.put(feedback, "replies", Enum.map(replies, fn(reply) ->
        Map.put(reply, "isOriginalPoster", is_original_poster?(reply, originalEmail))
      end))
    end)
  end

  # Public feedbacks should contain string '#public' by original poster in message body
  defp is_public?(%{"message" => message}), do: String.contains?(message, "#public")

  # Makes sure that the poster either has the same email as original poster,
  # or original poster was an anonymous user. Only employees can post anonymously.
  defp is_original_poster?(%{"userEmail" => replyEmail}, "") when is_nil(replyEmail), do: true
  defp is_original_poster?(%{"userEmail" => replyEmail}, originalEmail), do: replyEmail == originalEmail

  @doc """
  Fetches current tribe engagements from Officevibe API
  """
  def fetch_tribe_engagements(groupNames \\ fetch_groups()) do
    url = "#{System.get_env("OFFICEVIBE_API_URL")}/v2/engagement"
    token = System.get_env("OFFICEVIBE_API_TOKEN")
    headers = ["Authorization": "Bearer #{token}", "Content-Type": "application/json"]
    params = %{
      dates: [
        Timex.format!(Timex.shift(Timex.today, days: -1), "{ISOdate}")
      ],
      groupNames: groupNames
    }

    cache_key = url <> "#" <> inspect params

    Cachex.get!(:officevibe_cache, cache_key, fallback: fn(_request_url) ->
      case HTTPoison.post(url, Poison.encode!(params), headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          response = body
          |> Poison.decode!
          |> Map.get("data")
          |> Map.get("weeklyReports")
          |> Enum.map(fn(%{"metricsValues" => metricsValues, "groupName" => groupName}) ->
            %{name: groupName,
              value: Map.get(Enum.find(metricsValues, fn(%{"id" => id} = _metric) -> id === "Engagement" end), "value", 0)}
          end)

          { :commit, response }
        {:ok, %HTTPoison.Response{status_code: 404}} ->
          Logger.error("Failed to fetch engagements")
          []
          { :ignore, [] }
        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("API error with engagements: #{inspect reason}")
          { :ignore, reason }
      end
    end)
  end

  @doc """
  Fetches metrics from Officevibe API
  """
  def fetch_metrics(groupName \\ nil) do
    url = "#{System.get_env("OFFICEVIBE_API_URL")}/v2/engagement"
    token = System.get_env("OFFICEVIBE_API_TOKEN")
    headers = ["Authorization": "Bearer #{token}", "Content-Type": "application/json"]
    params = %{
      dates: generate_history_dates(),
      groupNames: groupName
    }

    cache_key = url <> "#" <> inspect params

    Cachex.get!(:officevibe_cache, cache_key, fallback: fn(_request_url) ->
      case HTTPoison.post(url, Poison.encode!(params), headers) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          metrics = body
          |> pick_whitelisted_metrics(@metrics_whitelist)
          |> reverse_metrics_values

          engagement = body
          |> pick_whitelisted_metrics(["Engagement"])
          |> List.first

          { :commit, %{metrics: metrics, engagement: engagement} }
        {:ok, %HTTPoison.Response{status_code: 404}} ->
          Logger.error("Failed to fetch engagements (metrics)")
          { :ignore, %{metrics: [], engagement: %{}} }
        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("API error with engagements (metrics): #{inspect reason}")
          { :ignore, reason }
      end
    end)
  end

  defp pick_whitelisted_metrics(body, whitelist) do
    reports = body
    |> Poison.decode!
    |> Map.get("data")
    |> Map.get("weeklyReports")

    Enum.flat_map(reports,
      fn(%{"metricsValues" => metricsValues, "date" => date}) ->
        metricsValues
        |> Enum.filter(fn(%{"id" => metric_id}) -> Enum.member?(whitelist, metric_id) end)
        |> Enum.map(fn(metric) -> Map.put(metric, "date", date) end)
      end)
    |> Enum.group_by(fn(%{"id" => id}) -> id end)
    |> Map.values
    |> Enum.map(fn([head | _] = weeklyMetrics) ->
      %{id: head["id"],
        name: head["displayName"],
        values: Enum.map(weeklyMetrics, fn(metric) -> Map.take(metric, ["value", "date"]) end)}
    end)
  end

  defp reverse_metrics_values(metrics) do
    Enum.map(metrics, fn(%{values: values} = metric) ->
      %{metric | values: Enum.reverse(values)}
    end)
  end

  # Generates array of week start dates from start until endDate, defaulting to today.
  defp generate_history_dates(%Date{} = endDate \\ Timex.today) do
    endDate
    |> Stream.iterate(&(Timex.shift(&1, weeks: -1)))
    |> Stream.take_while(&(is_within_max_history?(&1)) and is_after_trial_period?(&1))
    |> Enum.map(&Timex.format!(&1, "{ISOdate}"))
  end

  defp is_within_max_history?(%Date{} = date) do
    Timex.after?(date, Timex.shift(Timex.today, @max_metrics_history))
  end

  defp is_after_trial_period?(%Date{} = date) do
    Timex.after?(date, @trial_end_date)
  end
end
