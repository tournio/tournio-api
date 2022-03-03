FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "test_user_#{n}@example.com" }
    password { 'qwertyuiop' }
  end

  trait :superuser do
    role { :superuser }
  end

  trait :director do
    role { :director }
  end

  trait :unpermitted do
    role { :unpermitted }
  end
end
