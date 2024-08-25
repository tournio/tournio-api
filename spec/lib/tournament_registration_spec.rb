# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TournamentRegistration do
  let(:subject_class) { described_class }

  describe '#person_list_name' do
    subject { subject_class.person_list_name(person) }

    let(:first_name) { 'Aragorn' }
    let(:last_name) { 'Arathorn' }
    let(:person) { create :person, first_name: first_name, last_name: last_name }

    it 'uses the first name' do
      expect(subject).to eq("#{last_name}, #{first_name}")
    end

    context 'with a nickname specified' do
      let(:nickname) { 'Strider' }
      let(:person) { create :person, first_name: first_name, last_name: last_name, nickname: nickname }

      it 'uses the nickname' do
        expect(subject).to eq("#{last_name}, #{nickname}")
      end
    end
  end

  describe '#person_display_name' do
    subject { subject_class.person_display_name(person) }

    let(:first_name) { 'Aragorn' }
    let(:last_name) { 'Arathorn' }
    let(:person) { create :person, first_name: first_name, last_name: last_name }

    it 'uses the first name' do
      expect(subject).to eq("#{first_name} #{last_name}")
    end

    context 'with a nickname specified' do
      let(:nickname) { 'Strider' }
      let(:person) { create :person, first_name: first_name, last_name: last_name, nickname: nickname }

      it 'uses the nickname' do
        expect(subject).to eq("#{nickname} #{last_name}")
      end
    end
  end

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

    let(:tournament) { create :tournament, timezone: 'America/New_York' }
    let(:time_arg) { DateTime.parse('2018-07-04T12:05:22-04:00') }

    context 'when the tournament exists' do
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

      it 'formats the given time for the Eastern time zone' do
        expect(subject[-3, 3]).to eq('EDT')
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
    let(:tournament) { create :one_shift_standard_tournament, :active }
    let(:team) { Team.new(form_data.merge(tournament: tournament, shift_id: tournament.shifts.first.id)) }

    before do
      allow(subject_class).to receive(:register_bowler)
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
      expect { subject }.to change { Bowler.count }.by(form_data['bowlers_attributes'].count)
    end

    it 'Creates a person for each Bowler on the team' do
      expect { subject }.to change { Person.count }.by(form_data['bowlers_attributes'].count)
    end
  end

  describe '#register_bowler' do
    subject { subject_class.register_bowler(bowler) }

    let(:bowler) { create :bowler, :with_team }

    it 'queues up an email notification to the bowler' do
      expect(subject_class).to receive(:send_confirmation_email).with(bowler).once
      subject
    end

    it 'creates a data point' do
      expect { subject }.to change(DataPoint, :count).by(1)
    end

    describe 'signups' do
      before do
        create :purchasable_item, :optional_event,
          tournament: bowler.tournament
      end

      it 'creates a Signup for the optional bowling event' do
        expect { subject }.to change(Signup, :count).by(1)
      end
    end
  end

  describe '#amount_due' do
    subject { subject_class.amount_due(bowler) }

    let(:tournament) { create :tournament, :active, :with_entry_fee }
    let(:bowler) { create :bowler, tournament: tournament }
    let(:entry_fee_amount) { tournament.purchasable_items.entry_fee.first.value }

    it 'correctly says the entry fee amount' do
      expect(subject).to eq(entry_fee_amount)
    end

    context 'when the bowler has paid' do
      before do
        create :purchase, :paid,
          purchasable_item: tournament.purchasable_items.entry_fee.first,
          bowler: bowler,
          amount: entry_fee_amount
      end

      it 'says they owe nothing' do
        expect(subject).to eq(0)
      end
    end

    context 'when the bowler has a free entry' do
      before do
        create :free_entry,
          tournament: tournament,
          bowler: bowler,
          confirmed: true
      end

      it 'says they owe nothing' do
        expect(subject).to eq(0)
      end
    end

    context 'in early registration' do
      let(:tournament) { create :tournament, :active, :with_entry_fee, :with_early_discount }
      let(:discount_amount) { tournament.purchasable_items.early_discount.first.value }

      before do
        allow(tournament).to receive(:in_early_registration?).and_return(true)
        allow(tournament).to receive(:in_late_registration?).and_return(false)
      end

      it 'correctly says the entry fee amount minus discount' do
        expect(subject).to eq(entry_fee_amount - discount_amount)
      end

      context 'when the bowler has paid' do
        before do
          create :purchase, :paid,
            purchasable_item: tournament.purchasable_items.entry_fee.first,
            bowler: bowler,
            amount: entry_fee_amount
          create :purchase, :paid,
            purchasable_item: tournament.purchasable_items.early_discount.first,
            bowler: bowler,
            amount: discount_amount
        end

        it 'says they owe nothing' do
          expect(subject).to eq(0)
        end
      end

      context 'when the bowler has a free entry' do
        before do
          create :free_entry,
            tournament: tournament,
            bowler: bowler,
            confirmed: true
        end

        it 'says they owe nothing' do
          expect(subject).to eq(0)
        end
      end
    end

    context 'in late registration' do
      let(:tournament) { create :tournament, :active, :with_entry_fee, :with_late_fee }
      let(:late_fee_amount) { tournament.purchasable_items.late_fee.first.value }

      before do
        allow(tournament).to receive(:in_early_registration?).and_return(false)
        allow(tournament).to receive(:in_late_registration?).and_return(true)
      end

      it 'correctly says the entry fee amount plus fee' do
        expect(subject).to eq(entry_fee_amount + late_fee_amount)
      end

      context 'when the bowler has already paid just the entry fee' do
        before do
          create :purchase, :paid,
            purchasable_item: tournament.purchasable_items.entry_fee.first,
            bowler: bowler,
            amount: entry_fee_amount
        end

        it 'says they owe nothing' do
          expect(subject).to eq(0)
        end
      end

      context 'when the bowler has paid both' do
        before do
          create :purchase, :paid,
            purchasable_item: tournament.purchasable_items.entry_fee.first,
            bowler: bowler,
            amount: entry_fee_amount
          create :purchase, :paid,
            purchasable_item: tournament.purchasable_items.late_fee.first,
            bowler: bowler,
            amount: late_fee_amount
        end

        it 'says they owe nothing' do
          expect(subject).to eq(0)
        end
      end

      context 'when the bowler has a free entry' do
        before do
          create :free_entry,
            tournament: tournament,
            bowler: bowler,
            confirmed: true
        end

        it 'says they owe nothing' do
          expect(subject).to eq(0)
        end
      end

      context 'when the fee is waived' do
        before do
          create :waiver,
            bowler: bowler,
            purchasable_item: tournament.purchasable_items.late_fee.first
        end

        it 'shows the reduced amount owed' do
          expect(subject).to eq(entry_fee_amount)
        end
      end
    end

    # context 'when the bowler has signed up for extras' do
    #
    # end
  end


  describe '#amount_outstanding' do
    subject { subject_class.amount_outstanding(bowler) }

    let(:tournament) { create :tournament, :active, :with_entry_fee }
    let(:bowler) { create :bowler, tournament: tournament }
    let(:entry_fee_item) { tournament.purchasable_items.entry_fee.first }
    let(:entry_fee_amount) { entry_fee_item.value }

    it 'equals the entry fee amount' do
      expect(subject).to eq(entry_fee_amount)
    end

    context 'when the bowler has paid the entry fee' do
      before do
        create :purchase,
          :paid,
          bowler: bowler,
          purchasable_item: entry_fee_item,
          amount: entry_fee_item.value
      end

      it 'shows zero' do
        expect(subject).to eq(0)
      end
    end

    context 'when there is an optional event' do
      let(:tournament) do
        create :tournament,
          :active,
          :with_entry_fee,
          :with_an_optional_event
      end
      let(:optional_item) { tournament.purchasable_items.bowling.first }

      context 'and the bowler has signed up for it, but not paid for it' do
        before do
          create :signup,
            :requested,
            bowler: bowler,
            purchasable_item: optional_item
        end

        it 'reflects both charges' do
          expect(subject).to eq(entry_fee_amount + optional_item.value)
        end

        context 'and has also paid the entry fee' do
          before do
            create :purchase,
              :paid,
              bowler: bowler,
              purchasable_item: entry_fee_item,
              amount: entry_fee_item.value
          end

          it 'reflects just the optional item' do
            expect(subject).to eq(optional_item.value)
          end
        end
      end

      context 'and the bowler has signed up for it, and paid for it' do
        before do
          create :purchase,
            :paid,
            bowler: bowler,
            purchasable_item: optional_item,
            amount: optional_item.value
          create :signup,
            :paid,
            bowler: bowler,
            purchasable_item: optional_item
        end

        # This does not reflect the usual flow, but just in case
        it 'shows the entry fee as outstanding' do
          expect(subject).to eq(entry_fee_amount)
        end

        context 'and has also paid the entry fee' do
          before do
            create :purchase,
              :paid,
              bowler: bowler,
              purchasable_item: entry_fee_item,
              amount: entry_fee_item.value
          end

          it 'shows no outstanding balance' do
            expect(subject).to eq(0)
          end
        end
      end
    end
  end

  describe '#complete_doubles_link' do
    subject { subject_class.complete_doubles_link(new_bowler) }

    let(:tournament) { create :one_shift_standard_tournament, :active }
    let(:team) { create :team, tournament: tournament, shifts: [tournament.shifts.first] }

    context 'when no partner is available' do
      let(:new_bowler) { create(:bowler, person: create(:person), tournament: tournament, position: 3) }
      let(:bowlers) do
        [
          create(:bowler, person: create(:person), tournament: tournament, position: 1, doubles_partner_index: 1, team: team),
          create(:bowler, person: create(:person), tournament: tournament, position: 2, doubles_partner_index: 0, team: team),
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
          create(:bowler, person: create(:person), tournament: tournament, position: 1, doubles_partner_index: 1, team: team),
          create(:bowler, person: create(:person), tournament: tournament, position: 2, doubles_partner_index: 0, team: team),
          create(:bowler, person: create(:person), tournament: tournament, position: 3, team: team),
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

    let(:tournament) { create :tournament, :with_entry_fee, :active }
    let(:bowler) { create(:bowler, person: create(:person), tournament: tournament) }
    let(:confirmed) { false }
    let(:free_entry) { create :free_entry, tournament: tournament, bowler: bowler, confirmed: confirmed }
    let(:purchasable_item) { tournament.purchasable_items.entry_fee.first }

    it 'marks the free entry as confirmed' do
      subject
      expect(free_entry.reload.confirmed?).to be_truthy
    end

    it "adds two entries to the bowler's ledger" do
      expect { subject }.to change(bowler.ledger_entries, :count).by(2)
    end

    it 'creates an entry-fee purchase for the bowler' do
      expect { subject }.to change(bowler.purchases.entry_fee.paid, :count).by(1)
    end

    context 'when the entry fee purchase existed already' do
      let!(:purchase) { create :purchase, purchasable_item: purchasable_item, bowler: bowler }

      before do
        create :ledger_entry, bowler: bowler, debit: purchasable_item.value, identifier: 'entry fee'
      end

      it 'updates paid_at on the entry-fee purchase' do
        expect(purchase.paid_at).to be_nil
        subject
        expect(purchase.reload.paid_at).not_to be_nil
      end

      context 'and the bowler got an early registration discount' do
        let(:early_registration_discount) { 40 }
        let(:early_purchasable_item) do
          create :purchasable_item, :early_discount, value: early_registration_discount, tournament: tournament
        end
        let!(:early_purchase) { create :purchase, purchasable_item: early_purchasable_item, bowler: bowler }

        before do
          create :ledger_entry, bowler: bowler, credit: early_registration_discount, identifier: 'early registration'
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

      context 'and the bowler has a late-registration fee' do
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
        before do
          tournament.config_items.find_by(key: ConfigItem::Keys::EMAIL_IN_DEV).destroy
          tournament.config_items << ConfigItem.gimme(key_sym: :EMAIL_IN_DEV, initial_value: 'true')
        end

        it 'sends to the development address' do
          expect(RegistrationConfirmationNotifierJob).to receive(:perform_async).with(bowler.id, MailerJob::FROM)
          subject
        end
      end

      context 'with email_in_dev configured to be false' do
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
      expect(described_class.purchasable_item_sort(late_fee_item)).to be < described_class.purchasable_item_sort(scratch_item)
    end

    it 'puts the bowling item after the ledger item' do
      expect(described_class.purchasable_item_sort(late_fee_item)).to be < described_class.purchasable_item_sort(scratch_item)
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
      let(:item1) { create :purchasable_item, :optional_event, tournament: tournament, configuration: { order: 4} }
      let(:item2) { create :purchasable_item, :optional_event, tournament: tournament, configuration: { order: 2} }

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

  describe '#try_assigning_automatic_partners' do
    subject { subject_class.try_assigning_automatic_partners(team) }

    let(:tournament) { create :one_shift_standard_tournament, :active }
    let(:team) { create :team, tournament: tournament, shifts: [tournament.shifts.first] }

    context 'when the team is not yet full' do
      let(:new_bowler) { bowlers.last }
      context 'and no partners are assigned yet' do
        let(:bowlers) do
          [
            create(:bowler, person: create(:person), tournament: tournament, position: 3, team: team),
            create(:bowler, person: create(:person), tournament: tournament, position: 4, team: team),
          ]
        end

        it 'does nothing' do
          subject
          expect(new_bowler.reload.doubles_partner_id).to be_nil
        end
      end

      context 'and some partners are assigned' do
        let(:bowlers) do
          [
            create(:bowler, person: create(:person), tournament: tournament, position: 1, team: team),
            create(:bowler, person: create(:person), tournament: tournament, position: 2, team: team),
            create(:bowler, person: create(:person), tournament: tournament, position: 3, team: team),
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
    end

    context 'when the team is full' do
      let(:bowlers) do
        [
          create(:bowler, person: create(:person), tournament: tournament, position: 1, team: team),
          create(:bowler, person: create(:person), tournament: tournament, position: 2, team: team),
          create(:bowler, person: create(:person), tournament: tournament, position: 3, team: team),
          create(:bowler, person: create(:person), tournament: tournament, position: 4, team: team),
        ]
      end
      let(:new_bowler) { bowlers.last }

      context 'but the other bowlers are not yet partnered' do
        it 'does nothing' do
          subject
          expect(new_bowler.doubles_partner_id).to be_nil
        end
      end

      context 'and a partner is available' do
        let(:automatic_partner) { bowlers.third }

        before do
          bowlers.first.update(doubles_partner: bowlers.first)
          bowlers.second.update(doubles_partner: bowlers.second)
        end

        it 'links the doubles partners' do
          subject
          expect(new_bowler.reload.doubles_partner_id).to eq(automatic_partner.id)
        end

        it '... in both directions' do
          subject
          expect(automatic_partner.reload.doubles_partner_id).to eq(new_bowler.id)
        end
      end
    end
  end
end
