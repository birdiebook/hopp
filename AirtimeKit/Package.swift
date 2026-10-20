// swift-tools-version:5.9
//
// AirtimeKit — appens logik, fri från kamera och UI så att den går att testa på
// Linux (GitHub Actions) utan Mac och utan telefon. Appen i App/ är ett tunt skal.
import PackageDescription

let package = Package(
    name: "AirtimeKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Jump", targets: ["Jump"]),
    ],
    targets: [
        // Räkningen (METOD M1–M6): tiden i luften ur videons bildtider, höjden,
        // avstampsfarten, impulsen, effekten, dagarna och dagsformen. Bara Foundation.
        .target(name: "Jump"),
        .testTarget(name: "JumpTests", dependencies: ["Jump"]),
    ]
)
