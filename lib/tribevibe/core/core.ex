defmodule Tribevibe.Core do
  @moduledoc """
  The core functionality.
  """

  require Logger

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
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.error("Failed to fetch groups")
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("API error with groups: #{inspect reason}")
        reason
    end
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
        "2018-01-24"
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
      dates: [
        "2018-01-01",
        "2018-01-08",
        "2018-01-15",
        "2018-01-22",
        "2018-01-24",
      ]
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
        Enum.map(metricsValues, fn(metric) -> Map.put(metric, "date", date) end)
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
end
