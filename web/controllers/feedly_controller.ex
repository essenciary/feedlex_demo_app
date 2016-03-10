defmodule FeedlexDemo.FeedlyController do
  use FeedlexDemo.Web, :controller

  def index(conn, params) do
    if params["state"] == "waiting-callback" do
      case Feedlex.Auth.access_token(code: params["code"], state: "waiting-refresh-and-access-token") do
        {:ok, response} ->
          {mgs, s, _} = :erlang.timestamp

          {:ok, session_pid} = Agent.start_link fn -> %{} end

          conn
          |> put_session(:feedly_refresh_token, response["refresh_token"])
          |> put_session(:feedly_access_token, response["access_token"])
          |> put_session(:feedly_token_expiration, mgs * 1_000_000 + s + response["expires_in"])
          |> put_session(:session_pid, :erlang.term_to_binary(session_pid) |> Base.encode64)
          |> put_flash(:notice, "You have successfully logged into Feedly")
          |> redirect(to: FeedlexDemo.Router.Helpers.feedly_path(conn, :index))
        true ->
          text conn, "Feedly Authentication Failed"
      end
    end

    render conn, "index.html", authenticated: valid_authentication?(conn)
  end

  def refresh(conn, _params) do
    case Feedlex.Auth.refresh_access_token(refresh_token: get_session(conn, :feedly_refresh_token)) do
      {:ok, response} ->
        {mgs, s, _} = :erlang.timestamp

        conn
        |> put_session(:feedly_access_token, response["access_token"])
        |> put_session(:feedly_token_expiration, mgs * 1_000_000 + s + response["expires_in"])
        |> json(response)
      true ->
        text conn, "Feedly Token Refresh Failed"
    end
  end

  def logoff(conn, _param) do
    Feedlex.Auth.revoke_token(refresh_token: get_session(conn, :feedly_refresh_token))

    Agent.stop :erlang.binary_to_term(
      get_session(conn, :session_pid) |> Base.decode64!
    )

    conn
    |> delete_session(:feedly_access_token)
    |> delete_session(:feedly_refresh_token)
    |> delete_session(:feedly_token_expiration)
    |> delete_session(:feedly_subscriptions)
    |> put_flash(:notice, "You have successfully logged off from Feedly")
    |> redirect(to: FeedlexDemo.Router.Helpers.feedly_path(conn, :index))
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
    filters = Map.take(params, [:count, :ranked, :unread_only, :newer_than, :continuation])
    token = access_token(conn)
    case Feedlex.Stream.content(
      access_token: token,
      feed_id: params["feed_id"],
      filters: filters
    ) do
      {:ok, feed_contents} ->
        #json conn, feed_contents
        session = fetch_session(conn)
        session = Map.merge(session.private.plug_session,
          %{feed_id: params["feed_id"],
            filters: filters})

        pid_bin = get_session(conn, :session_pid) |> Base.decode64!
        pid = :erlang.binary_to_term(pid_bin)
        if Process.alive?(pid) do
          Agent.update(
            pid,
            &Map.merge(&1, session)
          )
        else
          {:ok, session_pid} = Agent.start_link fn -> session end
          pid_bin = :erlang.term_to_binary(session_pid) |> Base.encode64
          put_session(conn, :session_pid, pid_bin)
        end

        render conn, "articles.html", %{
          feed_contents: feed_contents,
          session_pid: pid_bin
        }
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
      {mgs, s, _} = :erlang.timestamp
      if get_session(conn, :feedly_token_expiration) > (mgs * 1_000_000 + s) do
        true
      else
        false
      end
    end
  end

  defp access_token(conn) do
    get_session(conn, :feedly_access_token)
  end
end
