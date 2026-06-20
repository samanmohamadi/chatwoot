class Conversations::TypingStatusManager
  include Events::Types

  attr_reader :conversation, :user, :params

  def initialize(conversation, user, params)
    @conversation = conversation
    @user = user
    @params = params
  end

  def trigger_typing_event(event, is_private)
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: @conversation, user: @user, is_private: is_private)
  end

  def toggle_typing_status
    case params[:typing_status]
    when 'on'
      trigger_typing_event(CONVERSATION_TYPING_ON, params[:is_private])
      forward_typing_action_to_channel unless params[:is_private]
    when 'off'
      trigger_typing_event(CONVERSATION_TYPING_OFF, params[:is_private])
    end
    # Return the head :ok response from the controller
  end

  private

  # Chatwoot's internal typing event powers web clients. Telegram needs its own
  # Bot API action, and the channel already owns the per-inbox bot credential.
  # The Telegram call is offloaded to a job to keep this request off the wire;
  # there is no Telegram "off" action, as it expires automatically after a few
  # seconds or when the bot sends the final message.
  def forward_typing_action_to_channel
    channel = conversation.inbox.channel
    return unless channel.is_a?(Channel::Telegram)

    Channels::Telegram::SendTypingActionJob.perform_later(conversation)
  end
end
