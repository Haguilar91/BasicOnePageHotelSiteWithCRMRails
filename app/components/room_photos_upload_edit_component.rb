# frozen_string_literal: true

# Custom edit view for Room's `photos` gallery field. The native
# `<input type="file" multiple>` that Avo renders by default only holds
# whatever was picked in the most recent dialog/drag — picking from a second
# folder wipes out the first selection. This swaps in a small JS layer
# (see avo_gallery_upload.js) that accumulates files picked or dropped across
# multiple rounds into one pending batch, submitted together on save.
#
# Wired up via `field :photos, as: :files, components: { edit_component: ... }`
# in app/avo/resources/room.rb — everything else about the field (param name,
# `.attach()` on save, validations) is untouched.
class RoomPhotosUploadEditComponent < Avo::Fields::FilesField::EditComponent
end
