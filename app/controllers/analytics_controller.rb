class AnalyticsController < ApplicationController
  def index
    @daily_revenue_data = PaymentTransaction.where(status: "pending")
                                            .group_by_day(:created_at)
                                            .sum(:amount)
  end
end
