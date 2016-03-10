defmodule FeedlexDemo.LivestreamChannel do
  use FeedlexDemo.Web, :channel
  use Phoenix.Channel

  intercept ["new_articles"]

  def join("livestream:all", _message, socket) do
    {:ok, socket}
  end
  def join("livestream:" <> _feed_id, _params, socket) do
    # TODO: implement for each feed ID
    {:ok, socket}
  end

  def handle_in(
    "new_articles",
    %{
      "last_updated" => last_updated,
      "pid" => session_pid,
    },
    socket
  ) do
    session = Agent.get(:erlang.binary_to_term(session_pid |> Base.decode64!), &(&1))
    filters = Map.merge(session.filters, %{
      newer_than: String.to_integer(last_updated) + 1
    })

    case Feedlex.Stream.content(
      access_token: Map.fetch!(session, "feedly_access_token"),
      feed_id: session.feed_id,
      filters: filters
    ) do
      {:ok, feed_contents} ->
        contents = for item <- feed_contents["items"], into: "" do
          Phoenix.View.render_to_string(
            FeedlexDemo.FeedlyView,
            "_article.html",
            item: item
          )
        end

        broadcast!(socket, "new_articles", %{
          body: contents,
          last_updated: feed_contents["updated"]
        })
    end

    {:noreply, socket}
  end

  def handle_out("new_articles", payload, socket) do
    push socket, "new_articles", payload
    {:noreply, socket}
  end

end
