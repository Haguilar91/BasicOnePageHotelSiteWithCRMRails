# frozen_string_literal: true

# Allow Avo icon helpers to render Font Awesome classes directly.
# This lets Avo menus and resource icons use Font Awesome class names
# instead of requiring an inline SVG asset.
Rails.application.config.to_prepare do
  next unless defined?(Avo::Icons::Helpers)

  Avo::Icons::Helpers.module_eval do
    alias_method :avo_svg_without_fontawesome, :svg unless method_defined?(:avo_svg_without_fontawesome)

    def svg(file_name, **args)
      return if file_name.blank?

      file_name = file_name.to_s.strip

      if font_awesome_icon?(file_name)
        content_tag(:i, nil, class: file_name)
      else
        avo_svg_without_fontawesome(file_name, **args)
      end
    end

    private

    def font_awesome_icon?(file_name)
      file_name.match?(%r{\A(?:fa[srlb]?|fab|fal|fad|far|fa-solid|fa-regular|fa-light|fa-duotone)\b}) ||
        file_name.match?(%r{\Afa-[a-z0-9-]+(?:\s+fa-[a-z0-9-]+)*\z}i)
    end
  end
end
