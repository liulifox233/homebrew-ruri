cask "5ire" do
  version "0.9.8"
  sha256 "625f1e9427644e5a7cc605ab41c6f9e927ec14c3bd4767466751c1e853aca2de"

  url "https://github.com/nanbingxyz/5ire/releases/download/v0.9.8/5ire-0.9.8-arm64.dmg"
  name "5ire"

  app "5ire.app"

  zap trash: [
    "~/Library/Application Support/5ire",
  ]
end
