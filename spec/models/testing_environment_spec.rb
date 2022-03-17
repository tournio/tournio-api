# == Schema Information
#
# Table name: testing_environments
#
#  id            :bigint           not null, primary key
#  conditions    :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_testing_environments_on_tournament_id  (tournament_id)
#
# Foreign Keys
#
#  fk_rails_...  (tournament_id => tournaments.id)
#
require 'rails_helper'

RSpec.describe TestingEnvironment, type: :model do
  describe 'validations' do
    context 'ensuring valid conditions' do
      subject { object.valid? }

      let(:object) do
        build :testing_environment,
              tournament: (create :tournament),
              conditions: conditions
      end

      context 'out of the box' do
        let(:conditions) { TestingEnvironment.defaultConditions }

        it { is_expected.to be_truthy }
      end

      context 'with an unknown condition name' do
        let(:conditions) { { minimum_average: '200' } }

        it { is_expected.to be_falsey }

        context 'in addition to a known one' do
          let(:conditions) do
            {
              minimum_average: '200',
              registration_period: TestingEnvironment::EARLY_REGISTRATION,
            }
          end

          it { is_expected.to be_falsey }
        end
      end

      context 'with an unknown value for a known condition' do
        let(:conditions) { { registration_period: 'very_early' } }

        it { is_expected.to be_falsey }
      end
    end
  end
end

