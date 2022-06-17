FactoryBot.define do
  factory :bowler_shift do

    trait :confirmed do
      after(:create) do |bs, _|
        bs.confirm!
      end
    end
  end
end
