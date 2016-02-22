defmodule FeedlexDemo.FeedlyController do
  use FeedlexDemo.Web, :controller

  require Logger

  # plug :action

  def index(conn, params) do
    if params["state"] == "waiting-callback" do
      case Feedlex.Auth.access_token(code: params["code"], state: "waiting-refresh-and-access-token") do
        {:ok, response} ->
          {mgs, s, _} = :erlang.now

          conn
          |> put_session(:feedly_refresh_token, response["refresh_token"])
          |> put_session(:feedly_access_token, response["access_token"])
          |> put_session(:feedly_token_expiration, mgs * 1_000_000 + s + response["expires_in"])
          |> put_flash(:notice, "You have successfully logged into Feedly")
          |> redirect to: FeedlexDemo.Router.Helpers.feedly_path(conn, :index)
        true ->
          text conn, "Feedly Authentication Failed"
      end
    end

    render conn, "index.html", authenticated: valid_authentication?(conn)
  end

  def refresh(conn, _params) do
    case Feedlex.Auth.refresh_access_token(refresh_token: get_session(conn, :feedly_refresh_token)) do
      {:ok, response} ->
        {mgs, s, _} = :erlang.now

        conn
        |> put_session(:feedly_access_token, response["access_token"])
        |> put_session(:feedly_token_expiration, mgs * 1_000_000 + s + response["expires_in"])
        |> json response
      true ->
        text conn, "Feedly Token Refresh Failed"
    end
  end

  def logoff(conn, _param) do
    Feedlex.Auth.revoke_token(refresh_token: get_session(conn, :feedly_refresh_token))

    conn
    |> delete_session(:feedly_access_token)
    |> delete_session(:feedly_refresh_token)
    |> delete_session(:feedly_token_expiration)
    |> delete_session(:feedly_subscriptions)
    |> put_flash(:notice, "You have successfully logged off from Feedly")
    |> redirect to: FeedlexDemo.Router.Helpers.feedly_path(conn, :index)
  end

  def subscriptions(conn, _params) do
    subscriptions = unless (get_session(conn, :feedly_subscriptions) |> is_nil) do
      get_session(conn, :feedly_subscriptions)
    else
      case Feedlex.Subscription.all(access_token: access_token(conn)) do
        {:ok, subscriptions} ->
          put_session(conn, :feedly_subscriptions, subscriptions)
          subscriptions
      end
    end

    render conn, "subscriptions.html", subscriptions: subscriptions
  end

  def show_feed(conn, params) do
    case Feedlex.Feed.one(access_token: access_token(conn), feed_id: params["feed_id"]) do
      {:ok, feed} ->
        render conn, "feed.html", feed: feed
      true ->
        text conn, "Sorry, an error was encountered while trying to get the feed details"
    end
  end

  def feed_articles(conn, params) do
    filters = %{unread_only: true}
    filters = if params["continuation"], do: Dict.merge(filters, %{continuation: params["continuation"]})

    case Feedlex.Stream.content(access_token: access_token(conn), feed_id: params["feed_id"], filters: filters) do
      {:ok, feed_contents} ->
        json conn, feed_contents
        render conn, "articles.html", feed_contents: feed_contents
    end
  end

  def authorize(conn, _params) do
    redirect conn, external: Feedlex.Auth.authenticate_uri(state: "waiting-callback")
  end

  def auth_callback(conn, params) do
    json conn, params
  end

  defp valid_authentication?(conn) do
    if is_nil access_token(conn) do
      false
    else
      {mgs, s, _} = :erlang.now
      if get_session(conn, :feedly_token_expiration) > (mgs * 1_000_000 + s) do
        true
      else
        false
      end
    end
  end

  defp access_token(conn) do
    token = get_session(conn, :feedly_access_token)
    Logger.info token

    token
  end
end
