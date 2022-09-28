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

  it 'sends a receipt email' do
    expect(TournamentRegistration).to receive(:send_receipt_email).once
    subject
  end
end
