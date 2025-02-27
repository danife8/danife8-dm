class Document < ApplicationRecord
  ## CONSTANTS
  VALID_FILE_CONTENT_TYPES = %w[
    application/msword
    application/pdf
    application/zip
    application/vnd.adobe.photoshop
    application/vnd.ms-excel
    application/vnd.ms-powerpoint
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    audio/mpeg
    audio/wav
    image/bmp
    image/gif
    image/jpeg
    image/png
    image/tiff
    image/vnd.adobe.photoshop
    image/webp
    image/x-icon
    text/csv
    text/plain
    video/mp4
    video/quicktime
    video/webm
    video/x-flv
    video/x-m2ts
    video/x-ms-wmv
    video/x-msvideo
  ].freeze
  FILES_FOR = %w[previous_campaign_data previous_customer_data creative_assets].freeze

  ## ASSOCIATIONS
  belongs_to :insertion_order
  has_one_attached :file, dependent: :purge_later
  has_one :campaign, through: :insertion_order
  has_one :documents_request, through: :insertion_order

  ## VALIDATIONS
  before_save :validate_uploaded_file
  validates :files_for, inclusion: {in: FILES_FOR, allow_nil: true}

  ## CALLBACKS
  after_create :set_title

  ## CLASS METHODS
  def self.valid_aasm_states
    []
  end

  private

  def validate_uploaded_file
    file_type
    file_size
    throw(:abort) if errors.any?
  end

  def file_type
    if file.attached? && !file.content_type.in?(VALID_FILE_CONTENT_TYPES)
      errors.add(:base, "#{file.filename} error: Invalid file Content-Type")
    end
  end

  def file_size
    if file.attached? && file.blob.byte_size > 25.megabytes
      errors.add(:base, "#{file.filename} error: Size should be less than 25MB")
    end
  end

  def set_title
    update(title: File.basename(file.filename.to_s, ".*"))
  end
end
