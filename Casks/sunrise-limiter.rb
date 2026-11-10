cask "sunrise-limiter" do
  version "0.1.7"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/mrBurma/SunriseLimiter/releases/download/v#{version}/Sunrise-Limiter-macOS-universal.zip"
  name "Sunrise Limiter"
  desc "Real-time system audio peak limiter for macOS"
  homepage "https://github.com/mrBurma/SunriseLimiter"

  depends_on macos: ">= :sonoma"

  app "Sunrise Limiter.app"
end
