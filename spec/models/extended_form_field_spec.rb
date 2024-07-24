# == Schema Information
#
# Table name: extended_form_fields
#
#  id                  :bigint           not null, primary key
#  helper_text         :string
#  helper_url          :string
#  html_element_config :jsonb
#  html_element_type   :string           default("input")
#  label               :string           not null
#  name                :string           not null
#  validation_rules    :jsonb
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
require 'rails_helper'

RSpec.describe ExtendedFormField, type: :model do
  describe 'validations' do
    let(:field_name) { 'something' }
    let(:field) { build :extended_form_field, name: field_name }

    subject { field.valid? }

    it { is_expected.to be_truthy }

    context 'a camelCased string' do
      let(:field_name) { 'someSillyAttribute' }

      it { is_expected.to be_truthy }
    end

    context 'with hyphens and digits' do
      let(:field_name) { 'some-attribute-42' }

      it { is_expected.to be_falsey }
    end

    context 'with uppercase letters and an underscore' do
      let(:field_name) { 'Some_Attribute' }

      it { is_expected.to be_falsey }
    end

    context 'with a space' do
      let(:field_name) { 'some attribute' }

      it { is_expected.to be_falsey }
    end

    context 'with other non-alphanumeric characters' do
      let(:field_name) { 'some_attribute!' }

      it { is_expected.to be_falsey }
    end
  end
end
