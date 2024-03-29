RSpec.shared_examples 'a Stripe event handler' do
  it 'raises no errors' do
    expect { subject }.not_to raise_error
  end
end

RSpec.shared_examples 'a completed checkout session' do
  it 'creates an ExternalPayment' do
    expect { subject }.to change(ExternalPayment, :count).by(1)
  end

  it 'creates a Stripe LedgerEntry for the bowler' do
    expect { subject }.to change { bowler.ledger_entries.stripe.count }.by(1)
  end

  it 'notifies tournament contacts who want to be notified individually' do
    expect(TournamentRegistration).to receive(:notify_payment_contacts).once
    subject
  end
end
