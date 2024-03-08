# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  first_name             :string
#  identifier             :string
#  last_name              :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default("unpermitted"), not null
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_identifier            (identifier) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "test_user_#{n}@example.com" }
    password { 'qwertyuiop' }
    role { :director }

    trait :superuser do
      role { :superuser }
    end

    trait :unpermitted do
      role { :unpermitted }
    end

    factory :user_with_orgs do
      transient do
        org_count { 1 }
      end

      after(:create) do |user, context|
        create_list(:tournament_org, context.org_count, users: [user])
        user.reload
      end
    end
  end
end
