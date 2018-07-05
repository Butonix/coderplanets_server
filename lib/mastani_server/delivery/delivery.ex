defmodule MastaniServer.Delivery do
  @moduledoc """
  The Delivery context.
  """
  alias MastaniServer.Delivery.Delegate.{Mentions, Notifications, Utils}

  defdelegate mailbox_status(user), to: Utils

  # system_notifications
  defdelegate publish_system_notification(info), to: Notifications
  defdelegate fetch_sys_notifications(user, filter), to: Notifications

  # mentions
  defdelegate mention_someone(from_user, to_user, info), to: Mentions
  defdelegate fetch_mentions(user, filter), to: Mentions

  # notifications
  defdelegate system_notify(info), to: Notifications
  defdelegate notify_someone(from_user, to_user, info), to: Notifications
  defdelegate fetch_notifications(user, filter), to: Notifications

  defdelegate fetch_record(user), to: Utils
  defdelegate mark_read_all(user, opt), to: Utils
end
