# Mixes OptimizableUpload into every ActiveStorage attachment; see that
# concern for what it does. `to_prepare` so it re-applies on each reload in
# development instead of only once at boot.
Rails.application.config.to_prepare do
  ActiveStorage::Attachment.include(OptimizableUpload)
end
