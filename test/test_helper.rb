ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # No `fixtures :all`, and no fixture files: almost every user-facing text
    # field in this app (Room#name, Offer#title, LocalActivity#description,
    # ...) lives in Mobility's key_value translation tables rather than in a
    # column of its own, so a fixture row simply cannot set one — it would
    # take a hand-maintained pair of polymorphic mobility_string_translations
    # / mobility_text_translations fixtures per field per locale. Tests build
    # the two or three records they need with the helpers below instead,
    # which go through the models and therefore write translations exactly
    # the way the app does.

    # Mobility writes a translated attribute into whichever locale is current
    # at assignment time. The app treats Spanish as the source language
    # everywhere it writes content (Avo runs in :es, and
    # EasyEditController#update wraps its writes in `Mobility.with_locale(:es)`),
    # so tests create records the same way unless they're specifically
    # exercising the English side.
    def create_es(model, **attributes)
      Mobility.with_locale(:es) { model.create!(**attributes) }
    end

    def create_user(email: "user@example.com", password: "password123", **attributes)
      User.create!(email:, password:, **attributes)
    end

    def create_admin(email: "admin@example.com", **attributes)
      create_user(email:, admin: true, **attributes)
    end

    # A real 1x1 PNG, small enough that attaching it stays under
    # OptimizableUpload::MIN_BYTES_TO_COMPRESS and never queues a background
    # compression job.
    PNG_1X1 = [
      "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4",
      "890000000a49444154789c6360000002000100fdff03fd0000000049454e44ae426082"
    ].join.freeze

    def image_upload(filename: "sample.png")
      {
        io: StringIO.new([ PNG_1X1 ].pack("H*")),
        filename: filename,
        content_type: "image/png"
      }
    end
  end
end
