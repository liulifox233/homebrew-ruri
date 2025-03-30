cask "5ire" do
  arch arm: "arm64"
  version "0.9.8"
  sha256 arm:   "034b94f53c6c4de34888fe03dbdd486efed044703d33a8e250c6bead30298294"
  url "https://github.com/nanbingxyz/5ire/releases/download/v0.9.8/5ire-0.9.8-#{arch}.dmg"
  name "5ire"
  app "5ire.app"
  zap trash: [
    "~/Library/Application Support/5ire",
  ]
end