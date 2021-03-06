defmodule TribevibeWeb.Router do
  use TribevibeWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TribevibeWeb do
    pipe_through :api

    get "/dashboard", VibeController, :dashboard_all
    get "/dashboard/:group", VibeController, :dashboard_group
    get "/groups", VibeController, :groups
    get "/feedback", VibeController, :feedback
    get "/feedback/:group", VibeController, :feedback_group
    get "/engagement", VibeController, :engagement
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
