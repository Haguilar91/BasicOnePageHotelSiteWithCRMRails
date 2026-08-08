# Fix AVO asset loading with Propshaft (Rails 8)
# Configure AVO assets properly with Propshaft

# Tell Propshaft where to find AVO's assets
avo_gem_path = Gem.loaded_specs["avo"].full_gem_path
Rails.application.config.assets.paths << File.join(avo_gem_path, "app", "assets")

# Add AVO's gem as an asset source if it's a gem
if defined?(Sprockets) || defined?(Propshaft)
  Rails.application.config.assets.paths << avo_gem_path
end

# Ensure AVO's CSS and JS assets are loaded
Rails.application.config.assets.precompile << %w(avo*.css avo*.js)
