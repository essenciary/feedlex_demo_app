defmodule FeedlexDemo.Router do
  use FeedlexDemo.Web, :router

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

  scope "/", FeedlexDemo do
    pipe_through :browser # Use the default browser stack

    get "/", FeedlyController, :index
    get "/feedly/callback", FeedlyController, :auth_callback
    get "/feedly/authorize", FeedlyController, :authorize
    get "/feedly/refresh", FeedlyController, :refresh
    get "/feedly/logoff", FeedlyController, :logoff
    get "/feedly/subscriptions", FeedlyController, :subscriptions, as: "feedly_subscriptions"
    get "/feedly/feeds/:feed_id", FeedlyController, :show_feed, as: "feedly_feed"
    get "/feedly/feeds/:feed_id/articles", FeedlyController, :feed_articles, as: "feedly_feed_articles"
 end

  # Other scopes may use custom stacks.
  # scope "/api", FeedlexDemo do
  #   pipe_through :api
  # end
end
