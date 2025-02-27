# Global controller + view helpers.
module ApplicationHelper
  def is_mobile?
    browser.device.mobile?
  end

  def viewport_meta_tag
    tag.meta(
      name: "viewport",
      content: is_mobile? ? "width=device-width,height=device-height,initial-scale=0.5,maximum-scale=5,minimum-scale=0.5,user-scalable=yes,viewport-fit=cover" : "width=device-width,initial-scale=1"
    )
  end

  def body_class
    is_mobile? ? "is-mobile-active" : ""
  end
end
