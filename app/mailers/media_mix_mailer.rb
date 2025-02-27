class MediaMixMailer < ApplicationMailer
  def pptx(media_mix_id, user_id)
    media_mix = MediaMix.find(media_mix_id)

    @ppt = url_for(media_mix.ppt_file)
    user = User.find(user_id)
    @full_name = user.full_name
    mail to: user.email, subject: "Your Media Mix Presentation is ready!"
  end
end
