# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DirectorUtilities do
  describe '#clear_test_data' do
    subject { described_class.clear_test_data(tournament: tournament) }

    before do
      # for the tournament under test
      team = create :team, tournament: tournament
      b1 = create :bowler, tournament: tournament, position: 1, team: team, person: create(:person)
      b2 = create :bowler, tournament: tournament, position: 2, team: team, person: create(:person)
      b3 = create :bowler, tournament: tournament, position: 3, team: team, person: create(:person)
      b4 = create :bowler, tournament: tournament, position: 4, team: team, person: create(:person)
      FreeEntry.create(tournament: tournament, unique_code: 'a-1')
      FreeEntry.create(tournament: tournament, unique_code: 'a-2', bowler: b1)
      LedgerEntry.create(bowler: b1, debit: 100)
      LedgerEntry.create(bowler: b2, debit: 100)
      LedgerEntry.create(bowler: b3, debit: 100)
      LedgerEntry.create(bowler: b4, debit: 100)
      LedgerEntry.create(bowler: b4, credit: 100)
    end

    # golden path
    context 'with a tournament in testing' do
      let!(:tournament) { create(:tournament, :testing) }

      it "drops all the tournament's teams" do
        expect { subject }.to change(tournament.teams, :count).to(0)
      end

      it "drops all the tournament's bowlers" do
        expect { subject }.to change(tournament.bowlers, :count).to(0)
      end

      it "drops all the tournament's free entries" do
        expect { subject }.to change(tournament.free_entries, :count).to(0)
      end

      it "drops all the tournament's ledger entries" do
        expect { subject }.to change(LedgerEntry, :count).to(0)
      end

      context 'when there are other tournaments in testing' do
        let!(:other_tournament) { create(:tournament, :testing) }

        before do
          # for the tournament under test
          team = create :team, tournament: other_tournament
          b1 = create :bowler, tournament: other_tournament, position: 1, team: team, person: create(:person)
          create :bowler, tournament: other_tournament, position: 2, team: team, person: create(:person)
          create :bowler, tournament: other_tournament, position: 3, team: team, person: create(:person)
          create :bowler, tournament: other_tournament, position: 4, team: team, person: create(:person)
          FreeEntry.create(tournament: other_tournament, unique_code: 'b-1')
          FreeEntry.create(tournament: other_tournament, unique_code: 'b-2', bowler: b1)
        end

        it { expect { subject }.not_to change(other_tournament.teams, :count) }
        it { expect { subject }.not_to change(other_tournament.bowlers, :count) }
        it { expect { subject }.not_to change(other_tournament.free_entries, :count) }
      end
    end

    context 'with an active tournament' do
      let!(:tournament) { create(:tournament, :active) }

      it { expect { subject }.not_to change(Team, :count) }
      it { expect { subject }.not_to change(Bowler, :count) }
      it { expect { subject }.not_to change(FreeEntry, :count) }
    end

    context 'with a closed tournament' do
      let!(:tournament) { create(:tournament, :closed) }

      it { expect { subject }.not_to change(Team, :count) }
      it { expect { subject }.not_to change(Bowler, :count) }
      it { expect { subject }.not_to change(FreeEntry, :count) }
    end
  end

  # describe '#assign_partner' do
  #   subject { described_class.assign_partner(bowler: bowler, new_partner: new_partner) }
  #
  #   let(:tournament) { create :tournament, :with_a_doubles_event }
  #   let(:bowler) { create(:bowler, tournament: tournament, person: create(:person)) }
  #   let(:new_partner) { create(:bowler, tournament: tournament, person: create(:person)) }
  #
  #   it 'results in the two bowlers being partners' do
  #     subject
  #     expect(bowler.reload.doubles_partner_id).to eq(new_partner.id)
  #     expect(new_partner.reload.doubles_partner_id).to eq(bowler.id)
  #   end
  #
  #   context 'when the tournament does not include event selection' do
  #     let(:tournament) { create :tournament, :standard }
  #
  #     it 'does nothing' do
  #       subject
  #       expect(bowler.reload.doubles_partner_id).to be_nil
  #       expect(new_partner.reload.doubles_partner_id).to be_nil
  #     end
  #   end
  #
  #   context 'when the tournament does not include a doubles event' do
  #     let(:tournament) { create :tournament, :with_a_bowling_event }
  #
  #     it 'does nothing' do
  #       subject
  #       expect(bowler.reload.doubles_partner_id).to be_nil
  #       expect(new_partner.reload.doubles_partner_id).to be_nil
  #     end
  #   end
  #
  #   context 'when the bowler already has a partner' do
  #     let(:existing_partner) { create :bowler, tournament: tournament, person: create(:person) }
  #
  #     before do
  #       bowler.update(doubles_partner: existing_partner)
  #       existing_partner.update(doubles_partner: bowler)
  #     end
  #
  #     it 'changes the partner assignment correctly' do
  #       subject
  #       expect(bowler.reload.doubles_partner_id).to eq(new_partner.id)
  #       expect(new_partner.reload.doubles_partner_id).to eq(bowler.id)
  #     end
  #
  #     it 'leaves the previous partner with no partner' do
  #       subject
  #       expect(existing_partner.reload.doubles_partner_id).to be_nil
  #     end
  #   end
  # end

  describe '#reassign_bowler' do
    subject { described_class.reassign_bowler(bowler: moving_bowler, to_team: destination_team) }

    let(:tournament) { create :two_shift_standard_tournament }
    let(:source_team_shift) { tournament.shifts.first }
    let(:destination_team_shift) { tournament.shifts.last }
    let(:b1) { create(:bowler, tournament: tournament, position: 1, person: create(:person)) }
    let(:b2) { create(:bowler, tournament: tournament, position: 2, person: create(:person)) }
    let(:b3) { create(:bowler, tournament: tournament, position: 3, person: create(:person)) }
    let(:moving_bowler) { create :bowler, tournament: tournament, position: 1, person: create(:person) }
    let(:from_team_bowlers) { [moving_bowler] }
    let(:dest_team_bowlers) { [b1, b2, b3] }
    let!(:from_team) { create :team, name: 'solo registrant', tournament: tournament, bowlers: from_team_bowlers }
    let!(:destination_team) { create :team, tournament: tournament, bowlers: dest_team_bowlers }

    before do
      b1.update(doubles_partner: b2)
      b2.update(doubles_partner: b1)
    end

    it 'increases the size of the destination team by 1' do
      expect { subject }.to change(destination_team.bowlers, :count).by(1)
    end

    it 'associates the moved bowler with the team' do
      subject
      expect(moving_bowler.reload.team.id).to eq(destination_team.id)
    end

    it 'decreases the size of the source team by 1' do
      expect { subject }.to change(from_team.bowlers, :count).by(-1)
    end

    it 'removes the bowler from the previous team' do
      subject
      expect(from_team.reload.bowlers.collect(&:id)).not_to include(moving_bowler.id)
    end

    it 'puts the bowler on the new team' do
      subject
      expect(destination_team.reload.bowler_ids).to include(moving_bowler.id)
    end

    it 'links the available doubles partner with the new bowler' do
      subject
      expect(b3.reload.doubles_partner_id).to eq(moving_bowler.id)
    end

    it 'does not change the other partners' do
      subject
      expect(b1.reload.doubles_partner_id).to eq(b2.id)
      expect(b2.reload.doubles_partner_id).to eq(b1.id)
    end

    it 'puts them in the first available position' do
      subject
      expect(moving_bowler.reload.position).to eq(4)
    end

    context 'when the destination team has only one bowler' do
      let(:dest_team_bowlers) { [b1] }

      before do
        b1.update(doubles_partner: nil)
      end

      it 'puts them in the first available position' do
        subject
        expect(moving_bowler.reload.position).to eq(2)
      end

      it 'links the only person with the new bowler' do
        subject
        expect(b1.reload.doubles_partner_id).to eq(moving_bowler.id)
      end
    end

    context 'when there is no available doubles partner' do
      let(:dest_team_bowlers) { [b1, b2] }

      it 'does not link the new bowler with a partner' do
        subject
        expect(moving_bowler.reload.doubles_partner_id).to be_nil
      end

      it 'puts them in the first available position' do
        subject
        expect(moving_bowler.reload.position).to eq(3)
      end
    end

    context 'when they had a doubles partner on their old team' do
      let(:remaining_bowler) { create :bowler, tournament: tournament, position: 2, person: create(:person) }
      let(:from_team_bowlers) { [moving_bowler, remaining_bowler] }

      before do
        moving_bowler.update(doubles_partner: remaining_bowler)
        remaining_bowler.update(doubles_partner: moving_bowler)
      end

      it 'removes the moving bowler from their original doubles partner' do
        subject
        expect(remaining_bowler.reload.doubles_partner_id).to be_nil
      end
    end

    context 'when the destination team is full' do
      let(:b4) { create(:bowler, tournament: tournament, position: 4, person: create(:person)) }
      let(:dest_team_bowlers) { [b1, b2, b3, b4] }

      before do
        b3.update(doubles_partner: b4)
        b4.update(doubles_partner: b3)
      end

      before { allow(tournament).to receive(:team_size).and_return(4) }

      it 'does not change the destination team size' do
        expect { subject }.not_to change(destination_team.bowlers, :count)
      end

      it 'does not change the origin team size' do
        expect { subject }.not_to change(from_team.bowlers, :count)
      end

      it 'does not add to the destination team bowlers' do
        subject
        expect(destination_team.reload.bowler_ids).not_to include(moving_bowler.id)
      end

      it 'keeps the bowler on the original team' do
        subject
        expect(from_team.reload.bowler_ids).to include(moving_bowler.id)
      end
    end
  end

  describe '#igbots_hash' do
    subject { described_class.igbots_hash(tournament: tournament) }

    let(:tournament) { create :one_shift_standard_tournament }
    let(:team) { create :team, tournament: tournament, shifts: tournament.shifts }
    let!(:b1) { create(:bowler, tournament: tournament, position: 1, person: create(:person), team: team) }
    let!(:b2) { create(:bowler, tournament: tournament, position: 2, person: create(:person), team: team) }
    let!(:b3) { create(:bowler, tournament: tournament, position: 3, person: create(:person), team: team) }
    let!(:b4) { create(:bowler, tournament: tournament, position: 4, person: create(:person), team: team) }

    it 'is a hash' do
      expect(subject).to be_instance_of(Hash)
    end

    it 'has the right structure' do
      result = subject
      expect(result.keys).to match_array [:peoples]
    end

    it 'has each registered bowler' do
      result = subject
      expect(result[:peoples].count).to eq(4)
    end
  end

  describe '#igbots_people' do
    subject { described_class.igbots_people(tournament: tournament) }

    let(:tournament) { create :one_shift_standard_tournament }
    let(:b1) { create(:bowler, tournament: tournament, position: 1, person: create(:person), team: team) }
    let(:b2) { create(:bowler, tournament: tournament, position: 2, person: create(:person), team: team) }
    let(:b3) { create(:bowler, tournament: tournament, position: 3, person: create(:person), team: team) }
    let(:b4) { create(:bowler, tournament: tournament, position: 4, person: create(:person), team: team) }

    context 'when there are doubles partners' do
      let(:team) { create :team, tournament: tournament }

      before do
        b1.update(doubles_partner: b2)
        b2.update(doubles_partner: b1)
        b3.update(doubles_partner: b4)
        b4.update(doubles_partner: b3)
      end

      it 'includes doubles partners' do
        result = subject
        doubles_last_names = result.map { |b| b[:doubles_last_name] }.compact
        expect(doubles_last_names.count).to eq(4)
      end
    end

    context 'when there are no doubles partners' do
      let(:team) { nil }

      it 'excludes doubles partners' do
        result = subject
        doubles_last_names = result.map { |b| b[:doubles_last_name] }.compact
        expect(doubles_last_names).to be_empty
      end
    end
  end

  describe '#csv_hash' do
    subject { described_class.csv_hash(tournament: tournament) }

    require 'csv'

    let(:shift_headers) { [] }
    let(:csv_headers) { [] }

    let(:tournament) { create :one_shift_standard_tournament }
    let(:entry_fee_amount) { 101 }
    let!(:entry_fee_item) { create(:purchasable_item, :entry_fee, value: entry_fee_amount, tournament: tournament) }

    it 'is an empty string' do
      expect(subject).to eq('')
    end

    context 'when bowler data are present' do
      let(:csv_headers) { %w[id last_name first_name nickname birth_day birth_month birth_year address1 address2 city state country postal_code phone email usbc_number team_id team_name team_order entry_fee_paid registered_at doubles_last_name doubles_first_name average handicap igbo_member] + shift_headers }

      context 'a bowler on a team' do
        let(:team) { create :team, tournament: tournament, shifts: tournament.shifts }
        let!(:b1) { create(:bowler, tournament: tournament, position: 1, person: create(:person), team: team) }
        let!(:b2) { create(:bowler, tournament: tournament, position: 2, person: create(:person), team: team) }
        let!(:b3) { create(:bowler, tournament: tournament, position: 3, person: create(:person), team: team) }
        let!(:b4) { create(:bowler, tournament: tournament, position: 4, person: create(:person), team: team) }

        before do
          b1.purchases << Purchase.new(purchasable_item: entry_fee_item)
          b2.purchases << Purchase.new(purchasable_item: entry_fee_item)
          b3.purchases << Purchase.new(purchasable_item: entry_fee_item)
          b4.purchases << Purchase.new(purchasable_item: entry_fee_item)

          b1.update(doubles_partner: b2)
          b2.update(doubles_partner: b1)
          b3.update(doubles_partner: b4)
          b4.update(doubles_partner: b3)
        end

        it 'is a string' do
          expect(subject).to be_instance_of(String)
        end

        it 'is parsable as CSV' do
          expect { CSV.parse(subject) }.not_to raise_error
        end

        it 'has each registered bowler' do
          parsed = CSV.parse(subject)
          expect(parsed.count).to eq(5) # one for header row, plus 4 bowlers
        end

        it 'has the right headers' do
          headers = CSV.parse_line(subject)
          expect(headers).to match_array(csv_headers)
        end

        context 'in a multi-shift tournament' do
          let(:tournament) { create :two_shift_standard_tournament }
          let(:shift) { tournament.shifts.first }

          let(:shift_headers) { ['shift preference'] }

          before do
            team.update(shifts: [shift]);
          end

          it 'has the right headers' do
            headers = CSV.parse_line(subject)
            expect(headers).to match_array(csv_headers)
          end

          it 'has the right shift' do
            parsed = CSV.parse(subject)
            shift_name = parsed[1][-1]
            expect(shift_name).to eq(shift.name)
          end
        end

        context 'in a mix-and-match tournament' do
          let(:tournament) { create :mix_and_match_standard_tournament }
          let(:sd_shift) { tournament.shifts.find_by(event_string: 'double_single') }
          let(:t_shift) { tournament.shifts.find_by(event_string: 'team') }

          let(:shift_headers) { ['shift preference: double_single', 'shift preference: team'] }

          before do
            team.update(shifts: [sd_shift, t_shift]);
          end

          it 'has the right headers' do
            headers = CSV.parse_line(subject)
            expect(headers).to match_array(csv_headers)
          end

          it 'has the right shifts' do
            parsed = CSV.parse(subject)
            cells = parsed[1][-2..-1]
            expect(cells).to eq([sd_shift.name, t_shift.name])
          end
        end
      end

      context 'a solo bowler' do
        let(:bowler_shifts) { tournament.shifts }

        before do
          create(:bowler,
            tournament: tournament,
            person: create(:person),
            shifts: bowler_shifts)
        end

        it 'is a string' do
          expect(subject).to be_instance_of(String)
        end

        it 'is parsable as CSV' do
          expect { CSV.parse(subject) }.not_to raise_error
        end

        it 'has each registered bowler' do
          parsed = CSV.parse(subject)
          expect(parsed.count).to eq(2) # one for header row, plus 1 bowler
        end

        it 'has the right headers' do
          headers = CSV.parse_line(subject)
          expect(headers).to match_array(csv_headers)
        end

        context 'in a multi-shift tournament' do
          let(:tournament) { create :two_shift_standard_tournament }
          let(:bowler_shifts) { [tournament.shifts.first] }

          let(:shift_headers) { ['shift preference'] }

          it 'has the right headers' do
            headers = CSV.parse_line(subject)
            expect(headers).to match_array(csv_headers)
          end

          it 'has the right shift' do
            parsed = CSV.parse(subject)
            shift_name = parsed[1][-1]
            expect(shift_name).to eq(tournament.shifts.first.name)
          end
        end

        context 'in a mix-and-match tournament' do
          let(:tournament) { create :mix_and_match_standard_tournament }
          let(:sd_shift) { tournament.shifts.find_by(event_string: 'double_single') }
          let(:t_shift) { tournament.shifts.find_by(event_string: 'team') }
          let(:bowler_shifts) { [sd_shift, t_shift] }
          let(:shift_headers) { ['shift preference: double_single', 'shift preference: team'] }

          it 'has the right headers' do
            headers = CSV.parse_line(subject)
            expect(headers).to match_array(csv_headers)
          end

          it 'has the right shifts' do
            parsed = CSV.parse(subject)
            cells = parsed[1][-2..-1]
            expect(cells).to eq([sd_shift.name, t_shift.name])
          end
        end

      end
    end
  end

  describe '#csv_purchases' do
    subject { described_class.csv_purchases(bowler: bowler) }

    let(:tournament) { create :one_shift_standard_tournament }
    let(:team) { create :team, tournament: tournament }
    let(:bowler) { create(:bowler, tournament: tournament, position: 1, person: create(:person), team: team) }
    let(:chosen_items) { [] }

    # When the tournament doesn't offer optional events
    it 'has no values purchasable items' do
      expect(subject.count).to be_zero
    end

    # When the tournament offers optional events, but nothing division-based
    context 'with some optional events offered' do
      before do
        os = create :purchasable_item, :optional_event, tournament: tournament, name: 'Optional Scratch'
        oh = create :purchasable_item, :optional_event, tournament: tournament, name: 'Optional Handicap'
        md = create :purchasable_item, :optional_event, tournament: tournament, name: 'Mystery Doubles'

        create :purchase, :paid, amount: os.value, bowler: bowler, purchasable_item: os
        create :purchase, :paid, amount: md.value, bowler: bowler, purchasable_item: md

        create :signup,             bowler: bowler, purchasable_item: oh
        create :signup, :paid,      bowler: bowler, purchasable_item: os
        create :signup, :paid,      bowler: bowler, purchasable_item: md
      end

      # expect the result to have three columns, with X's in the correct ones
      it 'has two columns for each optional event (one for signed up, one for paid)' do
        expect(subject.count).to eq(6)
      end

      it 'contains signup headers for all the optional events' do
        result = subject
        expect(result).to include('Signed up: Optional Scratch', 'Signed up: Optional Handicap', 'Signed up: Mystery Doubles')
      end

      it 'contains paid headers for all the optional events' do
        result = subject
        expect(result).to include('Paid: Optional Scratch', 'Paid: Optional Handicap', 'Paid: Mystery Doubles')
      end

      it 'indicates the purchased optional events' do
        result = subject
        expect(result).to include(
                            'Signed up: Optional Scratch' => 'X',
                            'Signed up: Mystery Doubles' => 'X',
                            'Signed up: Optional Handicap' => '',
                            'Paid: Optional Scratch' => 'X',
                            'Paid: Mystery Doubles' => 'X',
                            'Paid: Optional Handicap' => '',
                          )
      end

      context 'and one of them is signed up but not paid' do
        let(:oh_item) { tournament.purchasable_items.find_by_name('Optional Handicap') }
        before do
          bowler.signups.find_by_purchasable_item_id(oh_item.id).request!
        end

        it 'indicates the purchased optional events' do
          result = subject
          expect(result).to include(
            'Signed up: Optional Handicap' => 'X',
            'Paid: Optional Handicap' => '',
          )
        end
      end
    end

    # When the tournament offers division-based events like Scratch Masters
    context 'with a multi-division scratch competition' do
      let(:tournament) { create :tournament, :with_scratch_competition_divisions }
      let(:item) { tournament.purchasable_items.division.first }

      before do
        tournament.purchasable_items.division.each do |div_item|
          create :signup, bowler: bowler, purchasable_item: div_item
        end
      end

      it 'has two columns for each division in the event' do
        expect(subject.count).to eq(tournament.purchasable_items.division.count * 2)
      end

      it 'indicates that the bowler has not signed up for one' do
        result = subject
        item_key = "Signed up: #{item.name}: #{item.configuration['division']}"
        expect(result).to include(item_key => '')
      end

      it 'does not include the purchased indicator' do
        item_key = "Paid: #{item.name}: #{item.configuration['division']}"
        expect(subject).to include(item_key => '')
      end

      context 'and the bowler has signed up for one, but not yet paid' do
        before do
          bowler.signups.find_by_purchasable_item_id(item.id).request!
        end

        it 'indicates the one that the bowler has signed up for' do
          item_key = "Signed up: #{item.name}: #{item.configuration['division']}"
          expect(subject).to include(item_key => 'X')
        end

        it 'does not include the purchased indicator' do
          item_key = "Paid: #{item.name}: #{item.configuration['division']}"
          expect(subject).to include(item_key => '')
        end
      end

      context 'and the bowler has both signed up and paid for one' do
        before do
          create :purchase, :paid, amount: item.value, bowler: bowler, purchasable_item: item
          bowler.signups.find_by_purchasable_item_id(item.id).pay!
        end

        it 'indicates the one that the bowler has signed up for' do
          item_key = "Signed up: #{item.name}: #{item.configuration['division']}"
          expect(subject).to include(item_key => 'X')
        end

        it 'indicates the one that the bowler purchased' do
          item_key = "Paid: #{item.name}: #{item.configuration['division']}"
          expect(subject).to include(item_key => 'X')
        end
      end

      # When the tournament offers both kinds of events
      context 'and some optional events offered' do
        before do
          os = create :purchasable_item, :optional_event, tournament: tournament, name: 'Optional Scratch'
          oh = create :purchasable_item, :optional_event, tournament: tournament, name: 'Optional Handicap'
          md = create :purchasable_item, :optional_event, tournament: tournament, name: 'Mystery Doubles'

          create :signup, bowler: bowler, purchasable_item: os
          create :signup, bowler: bowler, purchasable_item: oh
          create :signup, bowler: bowler, purchasable_item: md
        end

        it 'has 2 columns for each division in the event and 2 for each optional event' do
          expect(subject.count).to eq((tournament.purchasable_items.division.count + 3) * 2)
        end
      end
    end

    # When the tournament offers multi-use items like banquet entries
    context 'with some multi-use items like banquet entries or raffle ticket bundles' do
      let(:tournament) { create :one_shift_standard_tournament, :with_extra_stuff }
      let(:items) do
        [
          tournament.purchasable_items.banquet.first,
          tournament.purchasable_items.raffle.first,
        ]
      end

      before do
        items.each { |i| create :purchase, :paid, amount: i.value, bowler: bowler, purchasable_item: i }
      end

      it 'has a column for each item offered' do
        expect(subject.count).to eq(items.count)
      end
    end

    context 'with a sanction item' do
      let(:tournament) { create :one_shift_standard_tournament, :with_sanction_item }
      let(:item) { tournament.purchasable_items.sanction.first }

      before { create :purchase, :paid, amount: item.value, bowler: bowler, purchasable_item: item }

      it 'has a column for the sanction item' do
        expect(subject).to include(item.name => 'X')
      end
    end
  end

  describe '#doubles_partner_info' do
    subject { described_class.doubles_partner_info(partner: partner, name_only: name_only?) }

    let(:tournament) { create :one_shift_standard_tournament }
    let(:team) { create :team, tournament: tournament }
    let(:b1) { create(:bowler, tournament: tournament, position: 1, person: create(:person), team: team) }
    let(:b2) { create(:bowler, tournament: tournament, position: 2, person: create(:person), team: team) }
    let(:partner) { b2 }
    let(:name_only?) { true }
    let(:name_only_keys) { %i[doubles_last_name doubles_first_name] }
    let(:additional_keys) { %i[doubles_external_id doubles_birth_month doubles_birth_day] }

    it 'has only name keys' do
      expect(subject.keys).to match_array(name_only_keys)
    end

    context 'with extra details' do
      let(:name_only?) { false }

      it 'has the additional keys' do
        expect(subject.keys).to match_array(name_only_keys + additional_keys)
      end
    end
  end

  describe '#csv_additional_questions' do
    subject { described_class.csv_additional_questions(bowler: bowler) }

    let(:tournament) { create :one_shift_standard_tournament }
    let(:team) { create :team, tournament: tournament }
    let(:bowler) { create(:bowler, tournament: tournament, position: 1, person: create(:person), team: team) }
    let(:comment_eff) { create :extended_form_field, :comment }
    let(:standings_eff) { create :extended_form_field, :standings_link }
    let(:pronouns_eff) { create :extended_form_field, :pronouns }
    let!(:comment_aq) { create :additional_question, tournament: tournament, extended_form_field: comment_eff, order: 3 }
    let!(:standings_aq) { create :additional_question, tournament: tournament, extended_form_field: standings_eff, order: 2 }
    let!(:pronouns_aq) { create :additional_question, tournament: tournament, extended_form_field: pronouns_eff, order: 1 }

    let(:comment_resp) { create :additional_question_response, bowler: bowler, extended_form_field: comment_eff, response: 'No comment' }
    let(:standings_resp) { create :additional_question_response, bowler: bowler, extended_form_field: standings_eff, response: 'www.igbo.org' }
    let(:pronouns_resp) { create :additional_question_response, bowler: bowler, extended_form_field: pronouns_eff, response: 'they/them' }

    it 'includes values for all the AQs even if the bowler provided no responses' do
      expect(subject.count).to eq(tournament.additional_questions.count)
    end

    it 'puts the responses in the order proscribed by the AQ order attributes' do
      expected_order = tournament.additional_questions.order(:order).collect(&:name)
      result_order = subject.keys
      expect(result_order).to eq(expected_order)
    end

    context 'when the bowler answered all the questions' do
      it 'includes all the responses' do
        expected_result = {
          pronouns_eff.name => pronouns_resp.response,
          standings_eff.name => standings_resp.response,
          comment_eff.name => comment_resp.response,
        }
        expect(subject).to eq(expected_result)
      end
    end

    context 'when the bowler answered some but not all of the questions' do
      it 'includes all the responses' do
        expected_result = {
          pronouns_eff.name => pronouns_resp.response,
          standings_eff.name => standings_resp.response,
          comment_eff.name => '',
        }
        expect(subject).to eq(expected_result)
      end
    end
  end

  describe '#bowler_export' do
    subject { described_class.bowler_export(bowler: bowler) }
    let(:tournament) { create :one_shift_standard_tournament }
    let(:bowler) do
      create :bowler,
        tournament: tournament,
        team: create(:team, tournament: tournament, shifts: tournament.shifts),
        person: create(:person)
    end
    let(:expected_keys) { %i(id last_name first_name nickname birth_day birth_month birth_year address city state country postal_code phone1 email usbc_number average handicap igbo_member) }

    before do
      tournament.config_items.find_by_key('bowler_form_fields').update(value: 'address1 city state country postal_code date_of_birth usbc_id')
    end

    it 'includes the expected keys' do
      exported_bowler = subject
      expect(exported_bowler.keys).to match_array(expected_keys)
    end

    context 'with all optional fields except USBC ID turned off' do
      let(:expected_keys) { %i(id last_name first_name nickname phone1 email usbc_number average handicap igbo_member) }

      before do
        tournament.config_items.find_by_key('bowler_form_fields').update(value: 'usbc_id')
      end

      it 'includes the expected keys' do
        exported_bowler = subject
        expect(exported_bowler.keys).to match_array(expected_keys)
      end
    end
  end
end
