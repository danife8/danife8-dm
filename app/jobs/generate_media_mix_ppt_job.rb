class GenerateMediaMixPptJob < ApplicationJob
  queue_as :default

  def perform(media_mix_id, user_id)
    media_mix = MediaMix.find(media_mix_id)
    file = MediaMixes::Presentation::Export.new(media_mix).call

    media_mix.ppt_file.attach(io: File.open(file.to_s), filename: "media-mix-#{media_mix.title.parameterize}-#{media_mix.id}.pptx")

    media_mix.save!

    MediaMixMailer.pptx(media_mix_id, user_id).deliver_later
  end
end
