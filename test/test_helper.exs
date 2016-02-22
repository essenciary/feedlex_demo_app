ExUnit.start

Mix.Task.run "ecto.create", ~w(-r FeedlexDemo.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r FeedlexDemo.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(FeedlexDemo.Repo)

