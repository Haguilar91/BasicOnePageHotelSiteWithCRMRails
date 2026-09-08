class RemoveAccentSoftAndTextMutedFromThemes < ActiveRecord::Migration[8.1]
  def change
    remove_column :themes, :accent_soft, :string
    remove_column :themes, :text_muted, :string
  end
end
