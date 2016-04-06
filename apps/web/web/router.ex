defmodule LotteryCorp.Web.Router do
  use LotteryCorp.Web.Web, :router

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

  scope "/", LotteryCorp.Web do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/operations/open-game", PageController, :open_game
    get "/operations/games/:id", PageController, :view_game
  end

  # Other scopes may use custom stacks.
  # scope "/api", LotteryCorp.Web do
  #   pipe_through :api
  # end
end
