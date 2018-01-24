defmodule TribevibeWeb.Router do
  use TribevibeWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TribevibeWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/api", TribevibeWeb do
    pipe_through :api

    get "/dashboard", VibeController, :dashboard_all
    get "/dashboard/:group", VibeController, :dashboard_group
    get "/groups", VibeController, :groups
    get "/feedback", VibeController, :feedback
  end

  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :tribevibe, swagger_file: "swagger.json", disable_validator: true
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "Tribevibe"
      }
    }
  end
end
