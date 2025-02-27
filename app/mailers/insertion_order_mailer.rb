class InsertionOrderMailer < ApplicationMailer
  def review_notification(id)
    @insertion_order = InsertionOrder.find(id)

    mail to: @insertion_order.media_plan.reviewer.email, subject: "A new Insertion Order is ready to view"
  end
end
