defmodule Tribevibe.Core do
  @moduledoc """
  The core functionality.
  """

  require Logger
  use Timex

  @followed_metrics [
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

  # Removes any groups that have '<' in their name
  defp filter_subgroups(groups) do
    Enum.filter(groups, fn(group) -> !String.contains?(group, ">") end)
  end

  @doc """
  Fetches a random feedback from Officevibe API
  """
  def fetch_random_feedback(_group \\ "Tammerforce") do
    url = "#{System.get_env("OFFICEVIBE_API_URL")}/v2/feedback"
    token = System.get_env("OFFICEVIBE_API_TOKEN")
    headers = ["Authorization": "Bearer #{token}"]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Poison.decode!
        |> Map.get("data")
        |> Map.get("conversations")
        |> Enum.random
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.error("Failed to fetch groups")
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("API error with groups: #{inspect reason}")
        reason
    end
  end

  @doc """
  Fetches list of feedbacks from Officevibe API
  """
  def fetch_feedbacks do
    url = "#{System.get_env("OFFICEVIBE_API_URL")}/v2/feedback"
    token = System.get_env("OFFICEVIBE_API_TOKEN")
    headers = ["Authorization": "Bearer #{token}"]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Poison.decode!
        |> Map.get("data")
        |> Map.get("conversations")
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.error("Failed to fetch groups")
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("API error with groups: #{inspect reason}")
        reason
    end
  end

  @doc """
  Fetches current tribe engagements from Officevibe API
  """
  def fetch_tribe_engagements(groups \\ fetch_groups()) do
    url = "#{System.get_env("OFFICEVIBE_API_URL")}/v2/engagement"
    token = System.get_env("OFFICEVIBE_API_TOKEN")
    headers = ["Authorization": "Bearer #{token}", "Content-Type": "application/json"]
    params = %{
      dates: [
        Timex.format!(Timex.today, "{ISOdate}")
      ],
      groupNames: groups
    }

    case HTTPoison.post(url, Poison.encode!(params), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        format_tribe_engagements(body)
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.error("Failed to fetch groups")
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("API error with groups: #{inspect reason}")
        reason
    end
  end

  @doc """
  Fetches metrics from Officevibe API
  """
  def fetch_metrics(_group \\ "Tammerforce") do
    url = "#{System.get_env("OFFICEVIBE_API_URL")}/v2/engagement"
    token = System.get_env("OFFICEVIBE_API_TOKEN")
    headers = ["Authorization": "Bearer #{token}", "Content-Type": "application/json"]
    params = %{
      dates: generate_week_dates()
    }

    case HTTPoison.post(url, Poison.encode!(params), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        format_metrics(body)
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.error("Failed to fetch groups")
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("API error with groups: #{inspect reason}")
        reason
    end
  end

  defp format_metrics(body) do
    reports = body
    |> Poison.decode!
    |> Map.get("data")
    |> Map.get("weeklyReports")

    Enum.flat_map(reports,
      fn(%{"metricsValues" => metricsValues, "date" => date}) ->
        metricsValues
        |> Enum.filter(fn(%{"id" => metric_id}) -> Enum.member?(@followed_metrics, metric_id) end)
        |> Enum.map(fn(metric) -> Map.put(metric, "date", date) end)
      end)
    |> Enum.group_by(fn(%{"id" => id}) -> id end)
    |> Map.values
    |> Enum.map(fn([head | _] = weeklyMetrics) ->
      %{id: head["id"],
        name: head["displayName"],
        values: Enum.reduce(weeklyMetrics, [], fn(%{"value" => value}, acc) -> [value | acc] end)}
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
  defp generate_week_dates(endDate \\ Timex.today) do
    Interval.new(from: ~D[2018-01-01], until: endDate)
      |> Interval.with_step([weeks: 1])
      |> Enum.map(&Timex.format!(&1, "{ISOdate}"))
  end
end
