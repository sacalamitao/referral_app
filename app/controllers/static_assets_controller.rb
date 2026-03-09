class StaticAssetsController < ActionController::Base
  def logo_png
    file_path = Rails.root.join("app", "assets", "images", "logo.png")
    return head :not_found unless File.exist?(file_path)

    send_file file_path, type: "image/png", disposition: "inline"
  end

  def icon_png
    send_public_asset("icon.png", "image/png")
  end

  def icon_svg
    send_public_asset("icon.svg", "image/svg+xml")
  end

  private

  def send_public_asset(filename, content_type)
    file_path = Rails.root.join("public", filename)
    return head :not_found unless File.exist?(file_path)

    send_file file_path, type: content_type, disposition: "inline"
  end
end
