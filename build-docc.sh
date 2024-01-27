##!/bin/sh

xcrun xcodebuild docbuild \
    -scheme Codability \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$PWD/.derivedData"

xcrun docc process-archive transform-for-static-hosting \
    "$PWD/.derivedData/Build/Products/Debug-iphonesimulator/Codability.doccarchive" \
    --output-path ".docs" \
    --hosting-base-path "Codability"

echo '<script>window.location.href += "documentation/codability"</script>' > .docs/index.html
