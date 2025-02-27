# frozen_string_literal: true

module MediaPlans
  module Presentation
    module Data
      # MediaPlans::Presentation::Data::Slide2
      class Slide2 < Base
        TEXTS = {
          phone_call: "Our campaign objective is to drive immediate and measurable actions from the target audience, focusing on direct response strategies to increase phone calls. By utilizing targeted messaging and compelling call-to-action, the campaign will increase these conversions, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          contact_form: "Our campaign objective is to drive immediate and measurable actions from the target audience, focusing on direct response strategies to increase contact form submissions. By utilizing targeted messaging and compelling call-to-action, the campaign will increase these conversions, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          ecommerce: "Our campaign objective is to drive immediate and measurable actions from the target audience, focusing on direct response strategies to increase ecommerce transactions. By utilizing targeted messaging and compelling call-to-action, the campaign will increase these conversions, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          instore_visit: "Our campaign objective is to drive immediate and measurable actions from the target audience, focusing on direct response strategies to increase in-store visits. By utilizing targeted messaging and compelling call-to-action, the campaign will increase these conversions, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          appointment: "Our campaign objective is to drive immediate and measurable actions from the target audience, focusing on direct response strategies to increase appointments scheduled. By utilizing targeted messaging and compelling call-to-action, the campaign will increase these conversions, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          app_download: "Our campaign objective is to drive immediate and measurable actions from the target audience, focusing on direct response strategies to increase app downloads. By utilizing targeted messaging and compelling call-to-action, the campaign will increase these conversions, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          file_download: "Our campaign objective is to drive immediate and measurable actions from the target audience, focusing on direct response strategies to increase file downloads. By utilizing targeted messaging and compelling call-to-action, the campaign will increase these conversions, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          newsletter_subscription: "Our campaign objective is to drive immediate and measurable actions from the target audience, focusing on direct response strategies to increase newsletter subscriptions. By utilizing targeted messaging and compelling call-to-action, the campaign will increase these conversions, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          promotion: "Our campaign objective is to drive immediate and measurable actions from the target audience, focusing on direct response strategies to increase promotion/giveaways. By utilizing targeted messaging and compelling call-to-action, the campaign will increase these conversions, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          request_quote: "Our campaign objective is to drive immediate and measurable actions from the target audience, focusing on direct response strategies to increase requested quotes. By utilizing targeted messaging and compelling call-to-action, the campaign will increase these conversions, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          job_recruitment: "Our campaign objective is to drive immediate and measurable actions from the target audience, focusing on direct response strategies to increase job applications. By utilizing targeted messaging and compelling call-to-action, the campaign will increase these conversions, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          coupon_download: "Our campaign objective is to drive immediate and measurable actions from the target audience, focusing on direct response strategies to increase coupon downloads. By utilizing targeted messaging and compelling call-to-action, the campaign will increase these conversions, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          fundraising: "Our campaign objective is to drive immediate and measurable actions from the target audience, focusing on direct response strategies to increase fundraising amounts. By utilizing targeted messaging and compelling call-to-action, the campaign will increase these conversions, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          traffic: "Our campaign objective is to drive immediate and measurable awareness from the target audience, focusing on awareness strategies to increase site traffic. By utilizing targeted messaging and compelling call-to-action, the campaign will increase visibility, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          reach: "Our campaign objective is to drive immediate and measurable awareness from the target audience, focusing on awareness strategies to increase familiarity reach. By utilizing targeted messaging and compelling call-to-action, the campaign will increase visibility, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          grand_opening: "Our campaign objective is to drive immediate and measurable awareness from the target audience, focusing on awareness strategies to increase grand opening traffic. By utilizing targeted messaging and compelling call-to-action, the campaign will increase visibility, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          max_exposure: "Our campaign objective is to drive immediate and measurable awareness from the target audience, focusing on awareness strategies to maximize awareness and brand exposure. By utilizing targeted messaging and compelling call-to-action, the campaign will increase visibility, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          product_launch: "Our campaign objective is to drive immediate and measurable awareness from the target audience, focusing on awareness strategies to increase new product launch traffic. By utilizing targeted messaging and compelling call-to-action, the campaign will increase visibility, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively.",
          brand_lift: "Our campaign objective is to drive immediate and measurable awareness from the target audience, focusing on awareness strategies to increase brand lift and familiarity. By utilizing targeted messaging and compelling call-to-action, the campaign will increase visibility, enhance customer engagement, and achieve specific, quantifiable results efficiently and effectively."
        }.freeze

        def call
          campaign_initiative = media_brief.campaign_initiative
          campaign_objetive = media_brief.campaign_objective

          {
            title: "CAMPAIGN OVERVIEW",
            campaign_title: campaign_initiative.label,
            campaign_label: "#{campaign_objetive.label} Objective",
            campaign_text: TEXTS[campaign_initiative.value.to_sym]
          }
        end

        def media_brief
          @media_brief ||= resource.media_brief
        end
      end
    end
  end
end
