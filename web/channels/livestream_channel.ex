defmodule FeedlexDemo.LivestreamChannel do
  use FeedlexDemo.Web, :channel
  use Phoenix.Channel

  intercept ["new_articles"]

  def join("livestream:all", _message, socket) do
    {:ok, socket}
  end
  def join("livestream:" <> feed_id, _params, socket) do
    # TODO: implement for each feed ID
    {:ok, socket}
  end

  def handle_in(
    "new_articles",
    %{
      "last_updated" => last_updated,
      "feedly_access_token" => feedly_access_token,
      "feed_id" => feed_id,
      "filters" => filters
    },
    socket
  ) do
    filters = Map.merge(filters, %{
      newer_than: String.to_integer(last_updated) + 1
    })

    case Feedlex.Stream.content(
      access_token: feedly_access_token,
      feed_id: feed_id,
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
