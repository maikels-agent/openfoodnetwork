# frozen_string_literal: true

RSpec.describe Orders::CaptureService do
  subject(:service) { described_class.new(order) }

  let(:order) { create(:order_with_totals) }

  it "captures a pending payment" do
    payment = create(:payment, order:, amount: order.total, state: "pending")

    expect(service.call).to be true
    expect(payment.reload).to be_completed
  end

  it "returns false when there is no pending payment" do
    create(:payment, :completed, order:, amount: order.total)

    expect(service.call).to be false
  end

  context "with an incomplete customer credit payment" do
    let!(:credit_payment) {
      create(:payment, order:, amount: 1, state: "checkout",
                       payment_method: Spree::PaymentMethod.customer_credit,
                       skip_source_validation: true, source: nil)
    }

    it "returns false when no other payment can be captured" do
      expect(service.call).to be false
      expect(credit_payment.reload.state).to eq "checkout"
    end

    it "captures the other pending payment and leaves the credit payment alone" do
      payment = create(:payment, order:, amount: order.total - 1, state: "checkout")

      expect(service.call).to be true
      expect(payment.reload).to be_completed
      expect(credit_payment.reload.state).to eq "checkout"
    end
  end
end
