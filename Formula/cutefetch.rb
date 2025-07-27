class Cutefetch < Formula
  desc "Tiny coloured fetch script with cute little animals"
  homepage "https://github.com/cybardev/cutefetch"
  url "https://github.com/cybardev/cutefetch/releases/download/v3.0.1/cutefetch"
  sha256 "3be740b5268416fd14ddd235bfe502d2b0631d42968fd98298c41164d005b537"
  license "GPL-3.0"

  def install
    bin.install "cutefetch"
    chmod 0755, bin/"cutefetch"
  end

end
