cask "stacher7" do
  arch arm: "arm64", intel: "x64"

  version "7.0.22"
  sha256 :no_check

  url "https://s7-releases.stacher-cloud.com/s7-releases/Stacher_Setup_#{version}_#{arch}.dmg"
  name "Stacher7"
  desc "GUI front-end for the YT-DLP video downloader"
  homepage "https://stacher.io"

  app "Stacher7.app"

  zap trash: [
    "~/Library/Application Support/Stacher7",
    "~/Library/Caches/com.electron.stacher7",
    "~/Library/Preferences/com.electron.stacher7.plist",
    "~/Library/Saved Application State/com.electron.stacher7.savedState",
  ]

end
