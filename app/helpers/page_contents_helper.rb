  module PageContentsHelper
    def dynamic_logo
      page_content = PageContent.find_by(key: 'global')
      return '/icon.png' unless page_content && page_content.logo.attached?

      rails_blob_path(page_content.logo, disposition: 'attachment')
    end

    def dynamic_favicon
      page_content = PageContent.find_by(key: 'global')
      return '/favicon.ico' unless page_content && page_content.favicon.attached?

      url_for(page_content.favicon)
    end

    def dynamic_app_icon
      page_content = PageContent.find_by(key: 'global')
      return '/apple-touch-icon.png' unless page_content && page_content.app_icon.attached?

      rails_blob_path(page_content.app_icon, disposition: 'attachment')
    end

    def page_content(key)
      pc = PageContent.find_by(key: key.to_s)
      return nil unless pc && pc.images.attached?

      url_for(pc.images.first)
    end
  end
