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

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Poison.decode!
        |> Map.get("data")
        |> Map.get("groups")
        |> Enum.map(fn(group) -> Map.get(group, "name") end)
        |> filter_subgroups
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.error("Failed to fetch groups")
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("API error with groups: #{inspect reason}")
        reason
    end
  end

  # Removes any groups that have '>' in their name
  defp filter_subgroups(groups) do
    Enum.filter(groups, fn(group) -> !String.contains?(group, ">") end)
  end

  @doc """
  Fetches newest feedbacks from Officevibe API that match criteria
  - Konstruktiiviset, joihin on vastattu
  - Positiiviset sellaisenaan (min. 20 kirjainta)
  - Näistä 10 uusinta
  - ainiin, ja sitten pitäisi olla #public jossain tekstibodyssä
  """
  def fetch_newest_feedbacks(groupName \\ nil) do
    url = "#{System.get_env("OFFICEVIBE_API_URL")}/v2/feedback"
    token = System.get_env("OFFICEVIBE_API_TOKEN")
    headers = ["Authorization": "Bearer #{token}"]
    options = [
      params: %{
        groupName: groupName
      }
    ]

    case HTTPoison.get(url, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Poison.decode!
        |> Map.get("data")
        |> Map.get("conversations")
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.error("Failed to fetch random feedback")
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("API error with feedbacks: #{inspect reason}")
        reason
    end
  end

  @doc """
  Fetches current tribe engagements from Officevibe API
  """
  def fetch_tribe_engagements(groupNames \\ fetch_groups()) do
    url = "#{System.get_env("OFFICEVIBE_API_URL")}/v2/engagement"
    token = System.get_env("OFFICEVIBE_API_TOKEN")
    headers = ["Authorization": "Bearer #{token}", "Content-Type": "application/json"]
    params = %{
      dates: [
        Timex.format!(Timex.today, "{ISOdate}")
      ],
      groupNames: groupNames
    }

    case HTTPoison.post(url, Poison.encode!(params), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        format_tribe_engagements(body)
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.error("Failed to fetch engagements")
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("API error with engagements: #{inspect reason}")
        reason
    end
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

    case HTTPoison.post(url, Poison.encode!(params), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        metrics = pick_whitelisted_metrics(body, @metrics_whitelist)
        engagement = pick_whitelisted_metrics(body, ["Engagement"]) |> List.first

        %{metrics: metrics, engagement: engagement}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.error("Failed to fetch engagements (metrics)")
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("API error with engagements (metrics): #{inspect reason}")
        reason
    end
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

  defp format_tribe_engagements(body) do
    body
    |> Poison.decode!
    |> Map.get("data")
    |> Map.get("weeklyReports")
    |> Enum.map(fn(%{"metricsValues" => metricsValues, "groupName" => groupName}) ->
      %{name: groupName,
        value: Map.get(Enum.find(metricsValues, fn(%{"id" => id} = _metric) -> id === "Engagement" end), "value", 0)}
    end)
  end

  # Generates array of week start dates from start until endDate, defaulting to today.
  defp generate_history_dates(%Date{} = endDate \\ Timex.today) do
    endDate
    |> Stream.iterate(&(Timex.shift(&1, weeks: -1)))
    |> Stream.take_while(&(isWithinMaxHistory(&1)) and isAfterTrialPeriod(&1))
    |> Enum.map(&Timex.format!(&1, "{ISOdate}"))
  end

  defp isWithinMaxHistory(%Date{} = date) do
    Timex.after?(date, Timex.shift(Timex.today, @max_metrics_history))
  end

  defp isAfterTrialPeriod(%Date{} = date) do
    Timex.after?(date, @trial_end_date)
  end
end
