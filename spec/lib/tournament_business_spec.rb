# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TournamentBusiness do
  let(:dummy_class) do
    Class.new do
      include TournamentBusiness

      def purchasable_items
        nil
      end

      def config_items
        nil
      end

      def name
        nil
      end

      def year
        nil
      end

      def id
        nil
      end

      def teams
        nil
      end

      def testing?
        nil
      end

      def demo?
        nil
      end

      def testing_environment
        nil
      end
    end
  end
  let(:dummy_obj) { dummy_class.new }

  let(:tournament) { create :tournament }

  before do
    allow(dummy_obj).to receive(:teams).and_return(tournament.teams)
    allow(dummy_obj).to receive(:id).and_return(tournament.id)
    allow(dummy_obj).to receive(:purchasable_items).and_return(tournament.purchasable_items)
    allow(dummy_obj).to receive(:config_items).and_return(tournament.config_items)
  end

  describe '#entry_fee' do
    subject { dummy_obj.entry_fee }

    before do
      create(:purchasable_item, :entry_fee, value: 150, tournament: tournament)
    end

    it { is_expected.to eq(150) }
  end

  describe '#display_name' do
    let(:tname) { 'Big Giant Fabulous Classic' }
    let(:tyear) { 2525 }

    before { allow(dummy_obj).to receive(:name).and_return(tname) }
    before { allow(dummy_obj).to receive(:year).and_return(tyear) }

    subject { dummy_obj.display_name }

    it 'includes the name and year' do
      expect(subject).to eq("#{tname} (#{tyear})")
    end
  end

  describe '#team_size' do
    subject { dummy_obj.team_size }

    context 'with no config item for team size' do
      it { is_expected.to eq(4) }
    end

    context 'with a config item for team size' do
      before do
        tournament.config_items << ConfigItem.new(key: 'team_size', value: 6)
      end

      it { is_expected.to eq(6) }
    end
  end

  describe '#config' do
    subject { dummy_obj.config }

    before do
      tournament.config_items << ConfigItem.new(key: 'dummyfoo', value: 'foo')
      tournament.config_items << ConfigItem.new(key: 'dummy17', value: '17')
      tournament.config_items << ConfigItem.new(key: 'dummytrue', value: 'true')
      tournament.config_items << ConfigItem.new(key: 'dummyfalse', value: 'false')
      tournament.config_items << ConfigItem.new(key: 'dummyf', value: 'f')
    end

    it 'returns a hash' do
      expect(subject).to be_instance_of(HashWithIndifferentAccess)
    end

    it 'has the correct key-value mapping' do
      result = subject
      expect(result[:dummyfoo]).to eq('foo')
      expect(result[:dummy17]).to eq('17')
    end

    it 'casts "true" and "false" to boolean' do
      result = subject
      expect(result[:dummytrue]).to be_instance_of(TrueClass)
      expect(result[:dummyfalse]).to be_instance_of(FalseClass)
    end

    it 'casts "f" to boolean false' do
      result = subject
      expect(result[:dummyf]).to be_instance_of(FalseClass)
    end
  end

  describe '#entry_deadline' do
    subject { dummy_obj.entry_deadline }

    it { is_expected.to be_instance_of DateTime }
  end

  describe '#late_fee_applies_at' do
    subject { dummy_obj.late_fee_applies_at }

    it { is_expected.to be_nil }

    context 'with a late registration date' do
      let(:start_time) { '1976-12-28T18:37:00-07:00' }
      let(:configuration) do
        {
          applies_at: start_time,
        }
      end

      before do
        create(:purchasable_item, :late_fee, value: 27, tournament: tournament, configuration: configuration)
      end

      it { is_expected.to be_instance_of DateTime }

      it { is_expected.to eq(DateTime.new(1976, 12, 28, 18, 37, 0, '-7')) }
    end
  end

  describe '#early_registration_ends' do
    subject { dummy_obj.early_registration_ends }

    it { is_expected.to be_nil }

    context 'when the tournament has an early registration end date' do
      let(:end_time) { '1976-12-28T18:37:00-07:00' }
      let(:configuration) do
        {
          valid_until: end_time,
        }
      end

      before do
        create(:purchasable_item, :early_discount, value: -13, tournament: tournament, configuration: configuration)
      end

      it { is_expected.to be_instance_of DateTime }

      it { is_expected.to eq(DateTime.new(1976, 12, 28, 18, 37, 0, '-7')) }
    end
  end

  describe '#paypal_client_id' do
    subject { dummy_obj.paypal_client_id }

    let(:value) { 'lay all your love on me' }

    before do
      create(:config_item, :paypal_client_id, tournament: tournament, value: value)
    end

    it { is_expected.to be_instance_of String }

    it { is_expected.to eq(value) }
  end

  describe '#available_to_join' do
    subject { dummy_obj.available_to_join }

    context 'with no teams registered' do
      it { is_expected.to be_empty }
    end

    context 'when one of the incomplete teams is empty' do
      let!(:team_a) { create :team, :standard_two_bowlers, name: 'The A Team', tournament: tournament }
      let!(:team_b) { create :team, tournament: tournament }

      it { is_expected.not_to be_empty }
      it { is_expected.to include(team_a) }
      it { is_expected.to include(team_b) }
    end

    context 'with some incomplete teams' do
      let!(:team_a) { create :team, :standard_two_bowlers, name: 'The A Team', tournament: tournament }
      let!(:team_b) { create :team, :standard_three_bowlers, name: 'The B Team', tournament: tournament }
      let!(:team_c) { create :team, :standard_full_team, name: 'The C Team', tournament: tournament }

      it { is_expected.not_to be_empty }

      it { is_expected.to include(team_a) }

      it { is_expected.to include(team_b) }

      it { is_expected.not_to include(team_c) }

    end

    context 'with only complete teams' do
      let!(:team_a) { create :team, :standard_full_team, name: 'The A Team', tournament: tournament }
      let!(:team_b) { create :team, :standard_full_team, name: 'The B Team', tournament: tournament }

      it { is_expected.to be_empty }
    end
  end

  describe '#in_early_registration?' do
    subject { dummy_obj.in_early_registration?(the_time) }

    let(:the_time) { Time.zone.now }

    context 'when the tournament is not in the testing nor demo state' do
      before do
        allow(dummy_obj).to receive(:testing?).and_return(false)
        allow(dummy_obj).to receive(:demo?).and_return(false)
      end

      context 'but no early registration discount is present' do
        it { is_expected.to eq(false) }
      end

      context 'and it has an early registration discount' do
        before do
          create(:purchasable_item, :early_discount, value: -13, tournament: tournament, configuration: pi_configuration)
        end

        let(:end_time) { '1976-12-28T18:37:00-07:00' }
        let(:pi_configuration) do
          {
            valid_until: end_time,
          }
        end

        context 'when the tournament is actually in early registration' do
          let(:the_time) { DateTime.parse(end_time) - 1.week }

          it { is_expected.to eq(true) }
        end

        context 'when the tournament is not in early registration' do
          let(:the_time) { DateTime.parse(end_time) + 1.week }

          it { is_expected.to eq(false) }
        end

      end
    end

    context 'when the tournament is in the testing state' do
      context 'with no testing environment' do
        it { is_expected.to eq(false) }
      end

      context 'and has a testing environment' do
        let(:period) { TestingEnvironment::REGULAR_REGISTRATION }
        let(:conditions) do
          {
            registration_period: period,
          }
        end
        let(:testing_environment) { create :testing_environment, tournament: tournament, conditions: conditions }

        before do
          allow(dummy_obj).to receive(:testing?).and_return(true)
          allow(dummy_obj).to receive(:testing_environment).and_return(testing_environment)
        end

        it { is_expected.to eq(false) }

        context 'configured for early registration' do
          let(:period) { TestingEnvironment::EARLY_REGISTRATION }

          it { is_expected.to eq(true) }
        end
      end
    end
  end

  describe '#in_late_registration?' do
    subject { dummy_obj.in_late_registration?(the_time) }

    let(:the_time) { Time.zone.now }

    context 'when the tournament is not in the testing state' do
      before do
        allow(dummy_obj).to receive(:testing?).and_return(false)
      end

      context 'but no late registration fee is present' do
        it { is_expected.to eq(false) }
      end

      context 'and it has a late registration fee' do
        before do
          create(:purchasable_item, :late_fee, value: 27, tournament: tournament, configuration: pi_configuration)
        end

        let(:applies_at_time) { '1976-12-28T18:37:00-07:00' }
        let(:pi_configuration) do
          {
            applies_at: applies_at_time,
          }
        end

        context 'when the tournament is actually in late registration' do
          let(:the_time) { DateTime.parse(applies_at_time) + 1.week }

          it { is_expected.to eq(true) }
        end

        context 'when the tournament is not in late registration' do
          let(:the_time) { DateTime.parse(applies_at_time) - 1.week }

          it { is_expected.to eq(false) }
        end

      end
    end

    context 'when the tournament is in the testing state' do
      context 'with no testing environment' do
        it { is_expected.to eq(false) }
      end

      context 'and has a testing environment' do
        let(:period) { TestingEnvironment::REGULAR_REGISTRATION }
        let(:conditions) do
          {
            registration_period: period,
          }
        end
        let(:testing_environment) { create :testing_environment, tournament: tournament, conditions: conditions }

        before do
          allow(dummy_obj).to receive(:testing?).and_return(true)
          allow(dummy_obj).to receive(:testing_environment).and_return(testing_environment)
        end

        it { is_expected.to eq(false) }

        context 'configured for late registration' do
          let(:period) { TestingEnvironment::LATE_REGISTRATION }

          it { is_expected.to eq(true) }
        end
      end
    end
  end
end
