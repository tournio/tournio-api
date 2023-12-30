# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StripeUtilities do
  let(:dummy_class) do
    Class.new do
      include StripeUtilities
    end
  end
  let(:dummy_obj) { dummy_class.new }

  let(:tournament) { create :tournament }

  describe '#build_checkout_session_items' do
    subject do
      dummy_obj.build_checkout_session_items(
        fees,
        discounts,
        items,
        item_quantities
      )
    end

    let(:fees) { [] }
    let(:discounts) { [] }
    let(:items) { [] }
    let(:item_quantities) { [] }

    it 'behaves correctly with empty arrays' do
      result = subject
      expect(result).to eq({
        line_items: [],
      })
    end

    context 'with an entry fee' do
      let(:entry_fee_item) do
        create :purchasable_item,
          :entry_fee,
          :with_stripe_product,
          tournament: tournament
      end
      let(:fees) { [entry_fee_item] }

      it 'behaves correctly' do
        result = subject
        expect(result).to eq({
          line_items: [
            {
              quantity: 1,
              price: entry_fee_item.stripe_product.price_id,
            }
          ],
        })
      end

      context 'and an early-registration discount' do
        let(:early_discount_item) do
          create :purchasable_item,
            :early_discount,
            :with_stripe_coupon,
            tournament: tournament
        end
        let(:discounts) { [early_discount_item] }

        it 'behaves correctly' do
          result = subject
          expect(result).to eq({
            line_items: [
              {
                quantity: 1,
                price: entry_fee_item.stripe_product.price_id,
              }
            ],
            discounts: [
              {
                coupon: early_discount_item.stripe_coupon.coupon_id,
              }
            ]
          })
        end
      end

      context 'and a late-registration fee' do
        let(:late_fee_item) do
          create :purchasable_item,
            :late_fee,
            :with_stripe_product,
            tournament: tournament
        end
        let(:fees) do
          [
            entry_fee_item,
            late_fee_item,
          ]
        end

        it 'behaves correctly' do
          result = subject
          expect(result).to eq({
            line_items: [
              {
                price: entry_fee_item.stripe_product.price_id,
                quantity: 1,
              },
              {
                price: late_fee_item.stripe_product.price_id,
                quantity: 1,
              }
            ],
          })
        end
      end
    end

    context 'with some optional items' do
      let(:item1) do
        create :purchasable_item,
          :optional_event,
          :with_stripe_product,
          tournament: tournament
      end
      let(:item2) do
        create :purchasable_item,
          :scratch_competition,
          :with_stripe_product,
          tournament: tournament
      end
      let(:multi_item) do
        create :purchasable_item,
          :raffle_bundle,
          :with_stripe_product,
          tournament: tournament
      end

      let(:items) do
        {
          item1.identifier => item1,
          item2.identifier => item2,
          multi_item.identifier => multi_item,
        }
      end
      let(:item_quantities) do
        [
          {
            identifier: item1.identifier,
            quantity: 1,
          },
          {
            identifier: item2.identifier,
            quantity: 1,
          },
          {
            identifier: multi_item.identifier,
            quantity: 3,
          },
        ]
      end

      it 'behaves correctly' do
        result = subject
        expect(result).to eq({
          line_items: [
            {
              quantity: 1,
              price: item1.stripe_product.price_id,
            },
            {
              quantity: 1,
              price: item2.stripe_product.price_id,
            },
            {
              quantity: 3,
              price: multi_item.stripe_product.price_id,
            },
          ],
        })
      end

    end
  end
end
