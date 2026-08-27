require "mini_magick"

# Re-encodes a freshly-uploaded image in place to cut its stored/served size
# without touching its resolution: strips EXIF/metadata, and for JPEGs (or
# PNGs that turn out to have no real transparency — e.g. a photo exported as
# PNG) re-compresses at a high-but-lossy quality. PNGs that do use
# transparency are left alone so logos/icons don't lose their alpha channel.
#
# Runs after the fact (via OptimizableUpload's after_create_commit) so it
# never adds latency to the request that did the attaching — see
# config/initializers/active_storage_image_optimization.rb.
class CompressImageJob < ApplicationJob
  queue_as :default

  QUALITY = "85"

  def perform(blob_id)
    blob = ActiveStorage::Blob.find_by(id: blob_id)
    return unless blob
    return if blob.metadata["compressed"]

    blob.open do |file|
      image = MiniMagick::Image.open(file.path)
      image.strip

      convert_to_jpeg = image.type == "PNG" && image["%[opaque]"].to_s.downcase == "true"
      image.format("jpg") if convert_to_jpeg

      image.quality(QUALITY) if convert_to_jpeg || %w[JPEG JPG].include?(image.type)

      image.write(file.path)

      if convert_to_jpeg
        blob.content_type = "image/jpeg"
        blob.filename = "#{blob.filename.base}.jpg"
      end
      blob.upload(File.open(file.path, "rb"))
      blob.metadata["compressed"] = true
      blob.save!
    end
  rescue MiniMagick::Error, MiniMagick::Invalid => e
    Rails.logger.warn("CompressImageJob: could not compress blob #{blob_id}: #{e.message}")
  end
end
