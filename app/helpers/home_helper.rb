module HomeHelper
  # Retrieves a specific page content value for the home page based on a key.
  # This allows you to manage content via your Avo admin panel instead of hardcoding it.
  #
  # @param key [String] The key defined in the PageContent model.
  # @return [String, nil]
  def home_content(key)
    PageContent.find_by(key: key)&.value
  end

  # Retrieves the Hero section data.
  # Assumes the 'hero' PageContent stores a hash with keys like 'title', 'description', and 'image'.
  #
  # @return [Hash, nil]
  def hero_section
    content = home_content(:hero)
    return nil unless content.is_a?(Hash)

    {
      title: content['title'] || content[:title],
      subtitle: content['subtitle'] || content[:subtitle],
      image_url: content['image_url'] || content[:image_url],
      cta_text: content['cta_text'] || content[:cta_text]
    }.compact
  end

  # Retrieves the Features section data.
  # Assumes the 'features' PageContent stores an array of feature hashes.
  #
  # @return [Array<Hash>]
  def features_section
    content = home_content(:features)
    return [] unless content.is_a?(Array)

    content.map do |feature|
      {
        title: feature['title'] || feature[:title],
        icon: feature['icon'] || feature[:icon],
        description: feature['description'] || feature[:description]
      }
    end
  end

  # Retrieves the Testimonials section data.
  # Assumes the 'testimonials' PageContent stores an array of testimonial hashes.
  #
  # @return [Array<Hash>]
  def testimonials_section
    content = home_content(:testimonials)
    return [] unless content.is_a?(Array)

    content
  end
end