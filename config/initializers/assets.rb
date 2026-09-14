# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

# A couple of image references in the original app point at files that were
# never actually checked in (e.g. sign_up.png). Rather than the asset
# pipeline raising a hard 500 for those, fall back to rendering the path
# as-is (a broken image, same as under the old public/ folder serving).
Rails.application.config.assets.unknown_asset_fallback = true
