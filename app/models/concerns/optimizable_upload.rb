# frozen_string_literal: true

# Queues CompressImageJob for every freshly-attached image above a size
# threshold, regardless of which model it's attached to (Room#photos,
# PageContent#logo, HeroImage#image, ...). Mixed into
# ActiveStorage::Attachment itself (see
# config/initializers/active_storage_image_optimization.rb) instead of each
# model, so newly attached models get it for free.
module OptimizableUpload
  extend ActiveSupport::Concern

  COMPRESSIBLE_TYPES = %w[image/jpeg image/png image/webp].freeze
  MIN_BYTES_TO_COMPRESS = 400.kilobytes

  included do
    after_create_commit :enqueue_image_compression
  end

  private

  def enqueue_image_compression
    return unless blob.content_type.in?(COMPRESSIBLE_TYPES)
    return if blob.byte_size < MIN_BYTES_TO_COMPRESS
    return if blob.metadata["compressed"]

    CompressImageJob.perform_later(blob.id)
  end
end
