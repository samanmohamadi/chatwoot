require 'rails_helper'

RSpec.describe Conversations::TypingStatusManager do
  describe '#toggle_typing_status' do
    let(:telegram_channel) { create(:channel_telegram) }
    let(:conversation) { create(:conversation, inbox: telegram_channel.inbox) }
    let(:user) { create(:user, account: conversation.account) }

    before { allow(Rails.configuration.dispatcher).to receive(:dispatch) }

    it 'forwards a public typing-on event to Telegram' do
      expect do
        described_class.new(conversation, user, typing_status: 'on', is_private: false).toggle_typing_status
      end.to have_enqueued_job(Channels::Telegram::SendTypingActionJob).with(conversation)
    end

    it 'does not forward private typing events to Telegram' do
      expect do
        described_class.new(conversation, user, typing_status: 'on', is_private: true).toggle_typing_status
      end.not_to have_enqueued_job(Channels::Telegram::SendTypingActionJob)
    end
  end
end
