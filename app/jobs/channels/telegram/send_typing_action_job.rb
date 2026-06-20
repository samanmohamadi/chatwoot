class Channels::Telegram::SendTypingActionJob < ApplicationJob
  # Time-sensitive: Telegram's typing action expires in a few seconds, so keep
  # it on a high-priority queue to land within that window.
  queue_as :high

  def perform(conversation)
    channel = conversation.inbox.channel
    return unless channel.is_a?(Channel::Telegram)

    channel.send_typing_action(conversation)
  rescue StandardError => e
    Rails.logger.warn "Telegram typing action failed for conversation #{conversation.display_id}: #{e.class}"
  end
end
