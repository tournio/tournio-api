# frozen_string_literal: true

require 'rails_helper'
# require 'team_spec_helper'

RSpec.describe TournamentRegistration do
  let(:subject_class) { described_class }

  describe '#display_date' do
    subject { subject_class.display_date(date_arg) }

    let(:date_arg) { Date.new(2018, 7, 4) }

    it 'formats the given date' do
      expect(subject).to eq('2018 Jul 4')
    end

    context 'with a nil date' do
      let(:date_arg) { nil }

      it 'returns n/a' do
        expect(subject).to eq('n/a')
      end
    end
  end

  describe '#display_time' do
    subject { subject_class.display_time(datetime: time_arg, tournament: tournament) }

    let(:tournament) { create :tournament }
    let(:config) { { time_zone: 'America/New_York' } }
    let(:time_arg) { DateTime.parse('2018-07-04T12:05:22-04:00') }

    context 'when the tournament exists' do
      before { allow(tournament).to receive(:config).and_return(config) }

      it "formats the given time for the tournament's time zone" do
        expect(subject[-3, 3]).to eq('EDT')
      end

      context 'when the time is nil' do
        let(:time_arg) { nil }

        it 'returns an N/A string' do
          expect(subject).to eq('n/a')
        end
      end
    end

    context 'when the tournament is nil' do
      let(:tournament) { nil }

      it 'returns a formatted time string' do
        expect(subject).not_to eq('n/a')
        expect(subject.length).to be > 0
      end

      it 'formats the given time for the Pacific time zone' do
        expect(subject[-3, 3]).to eq('PDT')
      end
    end
  end

  describe '#early_offset_time' do
    subject { subject_class.early_offset_time(time_arg) }

    let(:time_arg) { Time.zone.now + 3.weeks }

    it { is_expected.to eq(time_arg - 2.hours) }
  end

  describe '#max_bowlers' do
    subject { subject_class.max_bowlers(tournament) }

    let(:tournament) { instance_double('Tournament', team_size: 8) }

    it { is_expected.to eq(8) }
  end

  describe '#register_team' do
    subject { subject_class.register_team(team) }

    before do
      create :extended_form_field, :comment
      create :extended_form_field, :standings_link
      create :extended_form_field, :pronouns
    end

    # cleaned_up_form_data is defined in api_team_spec_helper.rb
    let(:form_data) { full_team_cleaned_up_form_data }
    let(:tournament) { create :tournament, :active }
    let(:team_size) { 4 }
    let(:team) { Team.new(form_data.merge(tournament: tournament)) }

    before do
      allow(subject_class).to receive(:register_bowler)
      allow(subject_class).to receive(:link_doubles_partners)
    end

    before do
      team.bowlers.each do |b|
        b.tournament = tournament
        b.free_entry.tournament = tournament if b.free_entry.present?
      end
    end

    it 'Creates a team' do
      expect { subject }.to change { Team.count }.by(1)
    end

    it 'Creates a Bowler for each position on the team' do
      expect { subject }.to change { Bowler.count }.by(team_size)
    end

    it 'Creates a person for each Bowler on the team' do
      expect { subject }.to change { Person.count }.by(team_size)
    end

    it 'Calls register_bowler for each bowler on the team' do
      expect(subject_class).to receive(:register_bowler).exactly(team_size).times
      subject
    end

    it 'Calls link_doubles_partners' do
      expect(subject_class).to receive(:link_doubles_partners).once
      subject
    end
  end

  describe '#register_bowler' do
    subject { subject_class.register_bowler(bowler) }

    let(:tournament) { create :tournament, :active }
    let(:bowler) { create(:bowler, person: create(:person), tournament: tournament) }

    before do
      allow(subject_class).to receive(:purchase_entry_fee)
      allow(subject_class).to receive(:add_late_fees_to_ledger)
    end

    it "adds the bowler's ledger items" do
      expect(subject_class).to receive(:purchase_entry_fee).with(bowler).once
      subject
    end

    it "adds discounts to the bowler's ledger items" do
      expect(subject_class).to receive(:add_early_discount_to_ledger).with(bowler).once
      subject
    end

    it "adds late fees to the bowler's ledger items" do
      expect(subject_class).to receive(:add_late_fees_to_ledger).with(bowler).once
      subject
    end

    it 'queues up an email notification to the bowler' do
      expect(subject_class).to receive(:send_confirmation_email).with(bowler).once
      subject
    end
  end

  describe '#purchase_entry_fee' do
    subject { subject_class.purchase_entry_fee(bowler) }

    let(:tournament) { create :tournament, :active }
    let(:entry_fee) { 100 }
    let(:bowler) { create(:bowler, person: create(:person), tournament: tournament) }

    before do
      allow(tournament).to receive(:entry_fee).and_return(entry_fee)
      create(:purchasable_item, :entry_fee, value: entry_fee, tournament: tournament)
    end

    it 'creates a ledger item for the tournament entry fee' do
      expect { subject }.to change(LedgerEntry, :count).by(1)
    end

    it 'associates the ledger entry with the bowler' do
      expect { subject }.to change(bowler.ledger_entries, :count).by(1)
    end

    it 'creates it as a debit' do
      subject
      debit_sum = bowler.ledger_entries.reload.sum(&:debit).to_i
      expect(debit_sum).to eq(entry_fee)
    end

    it 'creates no credit entries' do
      subject
      credit_sum = bowler.ledger_entries.reload.sum(&:credit).to_i
      expect(credit_sum).to eq(0)
    end

    it 'correctly populates the source property' do
      subject
      expect(LedgerEntry.last.registration?).to be_truthy
    end

    it 'creates a Purchase for the bowler' do
      expect { subject }.to change(bowler.purchases, :count).by(1)
    end

    it 'creates the right kind of Purchase' do
      subject
      purchase = bowler.purchases.reload.first
      expect(purchase.purchasable_item.determination).to eq('entry_fee')
    end
  end

  describe '#add_late_fees_to_ledger' do
    subject { subject_class.add_late_fees_to_ledger(bowler, time) }

    let(:time) { Time.zone.now }
    let(:bowler) { create(:bowler, person: create(:person), tournament: tournament) }
    let(:config) { {} }

    before { allow(tournament).to receive(:config).and_return(config) }

    let(:tournament) { create :tournament, :active }
    let(:late_fee) { 25 }

    it 'does not create a ledger entry' do
      expect { subject }.not_to change(LedgerEntry, :count)
    end

    it 'does not create a purchase' do
      expect { subject }.not_to change(Purchase, :count)
    end

    context 'with a late fee and date configured' do
      let(:configuration) do
        {
          applies_at: '1976-12-28T18:37:00-07:00',
        }
      end
      let!(:purchasable_item) { create(:purchasable_item, :late_fee, value: late_fee, tournament: tournament, configuration: configuration) }

      context 'not in late registration' do
        before { allow(tournament).to receive(:in_late_registration?).and_return(false) }

        it 'does not create a ledger entry' do
          expect { subject }.not_to change(LedgerEntry, :count)
        end

        it 'does not create a purchase' do
          expect { subject }.not_to change(Purchase, :count)
        end
      end

      context 'in late registration' do
        before { allow(tournament).to receive(:in_late_registration?).and_return(true) }

        it 'creates a ledger entry' do
          expect { subject }.to change(LedgerEntry, :count).by(1)
        end

        it 'creates a purchase' do
          expect { subject }.to change(Purchase, :count).by(1)
        end

        it 'creates a correct ledger entry for the late fee' do
          subject
          ledger_entry = LedgerEntry.last
          expect(ledger_entry.debit).to eq(late_fee)
          expect(ledger_entry.identifier).to eq('late registration')
        end

        it 'creates a purchase for the late fee' do
          subject
          purchase = Purchase.last
          expect(purchase.bowler_id).to eq(bowler.id)
          purchasable_item = tournament.purchasable_items.late_fee.first
          expect(purchase.purchasable_item_id).to eq(purchasable_item.id)
          expect(purchase.amount).to eq(purchasable_item.value)
        end
      end
    end
  end

  describe '#add_early_discount_to_ledger' do
    subject { subject_class.add_early_discount_to_ledger(bowler, time) }

    let(:time) { Time.zone.now }
    let(:discount_amount) { -17 }

    let(:tournament) { create :tournament, :active }
    let(:bowler) { create(:bowler, person: create(:person), tournament: tournament) }

    context 'when the tournament offers an early registration discount' do
      let(:configuration) do
        {
          valid_until: '1976-12-28T18:37:00-07:00',
        }
      end
      let!(:purchasable_item) { create(:purchasable_item, :early_discount, value: discount_amount, tournament: tournament, configuration: configuration) }

      context 'in early registration' do
        before { allow(tournament).to receive(:in_early_registration?).and_return(true) }

        it 'creates a purchase' do
          expect { subject }.to change(Purchase, :count).by(1)
        end

        it 'creates a ledger entry' do
          expect { subject }.to change(LedgerEntry, :count).by(1)
        end

        it 'creates a ledger entry for the discount' do
          subject
          ledger_entry = LedgerEntry.last
          expect(ledger_entry.debit).to be_zero
          expect(ledger_entry.credit).to eq(discount_amount * (-1))
          expect(ledger_entry.identifier).to eq('early registration')
        end

        it 'creates a purchase for the discount' do
          subject
          purchase = Purchase.last
          expect(purchase.bowler_id).to eq(bowler.id)
          expect(purchase.purchasable_item_id).to eq(tournament.purchasable_items.early_discount.first.id)
        end
      end

      context 'not in early registration' do
        before { allow(tournament).to receive(:in_early_registration?).and_return(false) }

        it 'does not create a ledger entry' do
          expect { subject }.not_to change(LedgerEntry, :count)
        end

        it 'does not create a purchase' do
          expect { subject }.not_to change(Purchase, :count)
        end
      end
    end

    context 'when the tournament does not offer an early registration discount' do
      context 'in early registration' do
        before { allow(tournament).to receive(:in_early_registration?).and_return(true) }

        it 'does not create a ledger entry' do
          expect { subject }.not_to change(LedgerEntry, :count)
        end

        it 'does not create a purchase' do
          expect { subject }.not_to change(Purchase, :count)
        end
      end
    end
  end

  describe '#add_discount_expiration_to_ledger' do
    subject { subject_class.add_discount_expiration_to_ledger(bowler, purchasable_item) }

    let(:bowler) { create(:bowler, person: create(:person), tournament: tournament) }
    let(:config) { {} }

    before { allow(tournament).to receive(:config).and_return(config) }

    let(:tournament) { create :tournament, :active }
    let(:amount) { 16 }
    let(:purchasable_item) { create :purchasable_item, :early_discount_expiration, value: amount }

    it 'does not create a ledger entry' do
      expect { subject }.to change(LedgerEntry, :count).by(1)
    end

    it 'does not create a purchase' do
      expect { subject }.to change(Purchase, :count).by(1)
    end

    it 'creates a correct ledger entry' do
      subject
      ledger_entry = LedgerEntry.last
      expect(ledger_entry.debit).to eq(amount)
      expect(ledger_entry.identifier).to eq('discount expiration')
    end

    it 'creates a corresponding purchase' do
      subject
      purchase = Purchase.last
      expect(purchase.bowler_id).to eq(bowler.id)
      expect(purchase.purchasable_item_id).to eq(purchasable_item.id)
      expect(purchase.amount).to eq(purchasable_item.value)
    end
  end

  describe '#amount_due' do
    subject { subject_class.amount_due(bowler) }

    let(:bowler) { instance_double('Bowler', ledger_entries: ledger_entries) }
    let(:ledger_entries) do
      [
        instance_double('LedgerEntry', debit: 30, credit: 0),
        instance_double('LedgerEntry', debit: 30, credit: 0),
        instance_double('LedgerEntry', debit: 30, credit: 0),
        instance_double('LedgerEntry', debit: 0, credit: 40),
      ]
    end

    it 'correctly diffs credits and debits' do
      expect(subject).to eq(50)
    end
  end

  describe '#amount_billed' do
    subject { subject_class.amount_billed(bowler) }

    let(:tournament) { create :tournament, :active }
    let(:bowler) { create :bowler, tournament: tournament }

    before do
      create :ledger_entry, debit: 30, bowler: bowler
      create :ledger_entry, debit: 30, bowler: bowler
      create :ledger_entry, debit: 30, bowler: bowler
      create :ledger_entry, credit: 40, source: :manual, bowler: bowler
    end

    it 'correctly sums debits' do
      expect(subject).to eq(90)
    end
  end

  describe '#link_doubles_partners' do
    subject { subject_class.link_doubles_partners(bowlers) }

    let(:tournament) { create :tournament, :active }

    context 'with a full team' do
      let(:bowlers) do
        [
          create(:bowler, tournament: tournament, position: 1, doubles_partner_num: 4),
          create(:bowler, tournament: tournament, position: 2, doubles_partner_num: 3),
          create(:bowler, tournament: tournament, position: 3, doubles_partner_num: 2),
          create(:bowler, tournament: tournament, position: 4, doubles_partner_num: 1),
        ]
      end

      it 'populates doubles_partner_id for all of them' do
        subject
        bowlers.map do |b|
          expect(b.reload.doubles_partner_id).not_to be_nil
        end
      end

      it 'correctly stores doubles partners' do
        subject
        updated_bowlers = Bowler.where(id: bowlers.map(&:id)).index_by(&:id)
        updated_bowlers.each_value do |b|
          partner_id = b.doubles_partner_id
          # expect the partner relationship to be reciprocal
          expect(updated_bowlers[partner_id].doubles_partner_id).to eq(b.id)
        end
      end
    end

    context 'with an odd number of bowlers' do
      context 'with one bowler missing a doubles partner' do
        let(:bowlers) do
          [
            create(:bowler, person: create(:person), tournament: tournament, position: 1),
            create(:bowler, person: create(:person), tournament: tournament, position: 2, doubles_partner_num: 3),
            create(:bowler, person: create(:person), tournament: tournament, position: 3, doubles_partner_num: 2),
          ]
        end

        it 'correctly stores doubles partners' do
          subject
          updated_bowlers = Bowler.where(id: bowlers.map(&:id)).index_by(&:id)

          first = bowlers[0]
          first_partner_id = updated_bowlers[first.id].doubles_partner_id
          expect(first_partner_id).to be_nil

          second = bowlers[1]
          third = bowlers[2]

          # expect the partner relationship to be reciprocal on both of them
          second_partner_id = updated_bowlers[second.id].doubles_partner_id
          third_partner_id = updated_bowlers[third.id].doubles_partner_id
          expect(second_partner_id).to eq(third.id)
          expect(third_partner_id).to eq(second.id)
        end
      end

      context 'when the odd bowler out has specified a number that does not yet exist' do
        let(:bowlers) do
          [
            create(:bowler, person: create(:person), tournament: tournament, position: 1, doubles_partner_num: 4),
            create(:bowler, person: create(:person), tournament: tournament, position: 2, doubles_partner_num: 3),
            create(:bowler, person: create(:person), tournament: tournament, position: 3, doubles_partner_num: 2),
          ]
        end

        it 'correctly stores doubles partners' do
          subject
          updated_bowlers = Bowler.where(id: bowlers.map(&:id)).index_by(&:id)

          first = bowlers[0]
          first_partner_id = updated_bowlers[first.id].doubles_partner_id
          expect(first_partner_id).to be_nil

          second = bowlers[1]
          third = bowlers[2]

          # expect the partner relationship to be reciprocal on both of them
          second_partner_id = updated_bowlers[second.id].doubles_partner_id
          third_partner_id = updated_bowlers[third.id].doubles_partner_id
          expect(second_partner_id).to eq(third.id)
          expect(third_partner_id).to eq(second.id)
        end
      end
    end

    context 'a single bowler' do
      context 'without specifying a doubles partner' do
        let(:bowlers) do
          [
            create(:bowler, person: create(:person), tournament: tournament, position: 3),
          ]
        end

        it 'correctly stores an empty doubles partner' do
          subject
          updated_bowlers = Bowler.where(id: bowlers.map(&:id)).index_by(&:id)

          first = bowlers[0]
          expect(updated_bowlers[first.id].doubles_partner_id).to be_nil
        end
      end

      context 'when specifying a number that does not yet exist' do
        let(:bowlers) do
          [
            create(:bowler, person: create(:person), tournament: tournament, position: 1, doubles_partner_num: 4),
          ]
        end

        it 'correctly stores an empty doubles partner' do
          subject
          updated_bowlers = Bowler.where(id: bowlers.map(&:id)).index_by(&:id)

          first = bowlers[0]
          first_partner_id = updated_bowlers[first.id].doubles_partner_id
          expect(first_partner_id).to be_nil
        end
      end
    end
  end

  describe '#complete_doubles_link' do
    subject { subject_class.complete_doubles_link(new_bowler) }

    let(:tournament) { create :tournament, :active }
    let(:team) { create :team, tournament: tournament }

    context 'when no partner is available' do
      let(:new_bowler) { create(:bowler, person: create(:person), tournament: tournament, position: 3) }
      let(:bowlers) do
        [
          create(:bowler, person: create(:person), tournament: tournament, position: 1, doubles_partner_num: 2, team: team),
          create(:bowler, person: create(:person), tournament: tournament, position: 2, doubles_partner_num: 1, team: team),
        ]
      end

      before do
        bowlers[0].update(doubles_partner: bowlers[1])
        bowlers[1].update(doubles_partner: bowlers[0])
      end

      it 'does nothing' do
        subject
        expect(new_bowler.doubles_partner_id).to be_nil
      end
    end

    context 'when a partner is available' do
      let(:bowlers) do
        [
          create(:bowler, person: create(:person), tournament: tournament, position: 1, doubles_partner_num: 2, team: team),
          create(:bowler, person: create(:person), tournament: tournament, position: 2, doubles_partner_num: 1, team: team),
          create(:bowler, person: create(:person), tournament: tournament, position: 3, doubles_partner_num: 4, team: team),
        ]
      end
      let(:new_bowler) { create(:bowler, person: create(:person), tournament: tournament, position: 4, doubles_partner: bowlers[2], team: team) }

      before do
        bowlers[0].update(doubles_partner: bowlers[1])
        bowlers[1].update(doubles_partner: bowlers[0])
      end

      it 'links the doubles partners in both directions' do
        subject
        expect(new_bowler.doubles_partner_id).to eq(bowlers[2].id)
      end

      it 'links the doubles partners in both directions' do
        expect { subject }.to change(bowlers[2], :doubles_partner_id).from(nil).to(new_bowler.id)
      end
    end
  end

  describe '#confirm_free_entry' do
    subject { subject_class.confirm_free_entry(free_entry) }

    let(:tournament) { create :tournament, :active }
    let(:bowler) { create(:bowler, person: create(:person), tournament: tournament) }
    let(:entry_fee) { 100 }
    let(:confirmed) { false }
    let(:free_entry) { create :free_entry, tournament: tournament, bowler: bowler, confirmed: confirmed }
    let(:purchasable_item) { create :purchasable_item, :entry_fee, value: entry_fee, tournament: tournament }
    let!(:purchase) { create :purchase, purchasable_item: purchasable_item, bowler: bowler }

    before do
      create :ledger_entry, bowler: bowler, debit: entry_fee, identifier: 'entry fee'
      # allow(tournament).to receive(:entry_fee).and_return(entry_fee)
    end

    it 'marks the free entry as confirmed' do
      subject
      expect(free_entry.reload.confirmed?).to be_truthy
    end

    it "adds an entry to the bowler's ledger" do
      expect { subject }.to change(bowler.ledger_entries, :count).by(1)
    end

    it 'updates paid_at on the entry-fee purchase' do
      expect(purchase.paid_at).to be_nil
      subject
      expect(purchase.reload.paid_at).not_to be_nil
    end

    context 'when the bowler got an early registration discount' do
      let(:early_registration_discount) { -40 }
      let(:early_purchasable_item) do
        create :purchasable_item, :early_discount, value: early_registration_discount, tournament: tournament
      end
      let!(:early_purchase) { create :purchase, purchasable_item: early_purchasable_item, bowler: bowler }

      before do
        create :ledger_entry, bowler: bowler, credit: early_registration_discount * (-1), identifier: 'early registration'
      end

      it 'updates paid_at on the entry-fee purchase' do
        expect(purchase.paid_at).to be_nil
        subject
        expect(purchase.reload.paid_at).not_to be_nil
      end

      it 'updates paid_at on the early-discount purchase' do
        expect(early_purchase.paid_at).to be_nil
        subject
        expect(early_purchase.reload.paid_at).not_to be_nil
      end
    end

    context 'when the bowler has a late-registration fee' do
      let(:late_fee) { 40 }
      let(:late_purchasable_item) do
        create :purchasable_item, :late_fee, value: late_fee, tournament: tournament
      end
      let!(:late_purchase) { create :purchase, purchasable_item: late_purchasable_item, bowler: bowler }

      before do
        create :ledger_entry, bowler: bowler, debit: late_fee, identifier: 'late registration'
      end

      it 'updates paid_at on the entry-fee purchase' do
        expect(purchase.paid_at).to be_nil
        subject
        expect(purchase.reload.paid_at).not_to be_nil
      end

      it 'updates paid_at on the early-discount purchase' do
        expect(late_purchase.paid_at).to be_nil
        subject
        expect(late_purchase.reload.paid_at).not_to be_nil
      end
    end

    context 'when the free entry is not linked to a bowler' do
      let(:free_entry) { create :free_entry, tournament: tournament, confirmed: confirmed }

      it 'raises' do
        expect { subject }.to raise_error(TournamentRegistration::IncompleteFreeEntry)
      end
    end

    context 'when the free entry is already confirmed' do
      let(:confirmed) { true }

      it 'raises' do
        expect { subject }.to raise_error(TournamentRegistration::FreeEntryAlreadyConfirmed)
      end
    end
  end

  describe '#bowler_paid?' do
    subject { subject_class.bowler_paid?(bowler) }

    let(:tournament) { create :tournament, :active }
    let(:bowler) { create(:bowler, person: create(:person), tournament: tournament) }

    before { allow(subject_class).to receive(:amount_due).and_return(amount_due) }

    context 'when the bowler still owes money' do
      let(:amount_due) { 100.0 }

      it { is_expected.to be_falsey }
    end

    context 'when the bowler is paid up' do
      let(:amount_due) { 0.0 }

      it { is_expected.to be_truthy }
    end
  end

  describe '#send_confirmation_email' do
    subject { subject_class.send_confirmation_email(bowler) }

    let(:recipient_email) { 'the_bowler@the.correct.domain' }
    let(:tournament) { create :tournament, :active }
    let(:bowler) { create(:bowler, person: create(:person, email: recipient_email), tournament: tournament) }

    before do
      allow(RegistrationConfirmationNotifierJob).to receive(:perform_async)
    end

    context 'in development' do
      before { allow(Rails.env).to receive(:development?).and_return(true) }

      context 'with email_in_dev configured to be true' do
        before { create(:config_item, :email_in_dev, tournament: tournament) }

        it 'sends to the development address' do
          expect(RegistrationConfirmationNotifierJob).to receive(:perform_async).with(bowler.id, MailerJob::FROM)
          subject
        end
      end

      context 'with email_in_dev configured to be false' do
        before { create(:config_item, :email_in_dev, tournament: tournament, value: 'false') }

        it 'sends no notification' do
          expect(RegistrationConfirmationNotifierJob).not_to receive(:perform_async)
          subject
        end
      end

      context 'with no email_in_dev config item' do
        it 'sends no notification' do
          expect(RegistrationConfirmationNotifierJob).not_to receive(:perform_async)
          subject
        end
      end
    end

    context 'in test' do
      it 'sends to the development address' do
        expect(RegistrationConfirmationNotifierJob).to receive(:perform_async).with(bowler.id, MailerJob::FROM)
        subject
      end
    end

    context 'in production' do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      context 'a tournament in test mode' do
        let(:tournament) { create :tournament, :testing }
        let(:addresses) { %w[foo@foo.foo foo@foo.org foo@foo.net] }

        before do
          allow(described_class).to receive(:test_mode_notification_recipients).and_return(addresses)
        end

        it 'does not send to the bowler' do
          expect(RegistrationConfirmationNotifierJob).not_to receive(:perform_async).with(bowler.id, recipient_email)
          subject
        end

        it "sends to the tournament's configured test-mode addresses" do
          expect(RegistrationConfirmationNotifierJob).to receive(:perform_async).exactly(3).times
          subject
        end
      end

      context 'an active tournament' do
        before do
          allow(described_class).to receive(:test_mode_notification_recipients).and_return(%w[foo@foo.foo])
        end

        it "sends to the bowler's address" do
          expect(RegistrationConfirmationNotifierJob).to receive(:perform_async).with(bowler.id, recipient_email)
          subject
        end

        it "does not send to the tournament's configured test-mode addresses" do
          expect(RegistrationConfirmationNotifierJob).not_to receive(:perform_async).with(bowler.id, 'foo@foo.foo')
          subject
        end
      end
    end
  end

  describe '#purchasable_item_sort' do
    let(:tournament) { create :tournament }

    let(:entry_fee_item) { create :purchasable_item, :entry_fee, tournament: tournament }
    let(:late_fee_item) { create :purchasable_item, :late_fee, tournament: tournament }
    let(:early_discount_item) { create :purchasable_item, :early_discount, tournament: tournament }
    let(:early_discount_expiration_item) { create :purchasable_item, :early_discount_expiration, tournament: tournament }
    let(:scratch_item) { create :purchasable_item, :scratch_competition, tournament: tournament }
    let(:optional_event_item) { create :purchasable_item, :optional_event, tournament: tournament }
    let(:banquet_item) { create :purchasable_item, :banquet_entry, tournament: tournament }
    let(:raffle_bundle_item) { create :purchasable_item, :raffle_bundle, tournament: tournament }

    it 'puts the entry fee item first' do
      expect(described_class.purchasable_item_sort(entry_fee_item)).to be < described_class.purchasable_item_sort(early_discount_item)
    end

    it 'puts the early discount item first' do
      expect(described_class.purchasable_item_sort(early_discount_item)).to be < described_class.purchasable_item_sort(late_fee_item)
    end

    it 'puts the late fee item first' do
      expect(described_class.purchasable_item_sort(late_fee_item)).to be < described_class.purchasable_item_sort(early_discount_expiration_item)
    end

    it 'puts the bowling item after the ledger item' do
      expect(described_class.purchasable_item_sort(early_discount_expiration_item)).to be < described_class.purchasable_item_sort(scratch_item)
    end

    it 'puts the scratch item first' do
      expect(described_class.purchasable_item_sort(scratch_item)).to be < described_class.purchasable_item_sort(optional_event_item)
    end

    it 'puts the bowling item before the banquet item' do
      expect(described_class.purchasable_item_sort(optional_event_item)).to be < described_class.purchasable_item_sort(banquet_item)
    end

    it 'puts the banquet item first' do
      expect(described_class.purchasable_item_sort(banquet_item)).to be < described_class.purchasable_item_sort(raffle_bundle_item)
    end

    context 'two items of the same kind' do
      let(:item1) { create :purchasable_item, :optional_event, configuration: { order: 4} }
      let(:item2) { create :purchasable_item, :optional_event, configuration: { order: 2} }

      it 'uses display order for items of the same kind' do
        expect(described_class.purchasable_item_sort(item1)).to be > described_class.purchasable_item_sort(item2)
      end
    end

    context 'with a purchase' do
      let(:bowler) { create :bowler, tournament: tournament }
      let(:purchase) { create :purchase, bowler: bowler, purchasable_item: entry_fee_item }

      it 'returns the same sort value' do
        expect(described_class.purchasable_item_sort(purchase)).to eq(described_class.purchasable_item_sort(entry_fee_item))
      end
    end
  end
end
