import ProjectDescription

let spm = SwiftPackageManagerDependencies([
    .remote(url: "https://github.com/Alamofire/Alamofire", requirement: .upToNextMinor(from: "5.6.4")),
    .remote(url: "https://github.com/pointfreeco/swift-composable-architecture", requirement: .upToNextMajor(from: "0.5.0"))
])

let dependencies = Dependencies(
    carthage: [],
    swiftPackageManager: spm,
    platforms: [.iOS]
)