import Foundation
import Path

/// The metadata associated with a precompiled framework (.framework)
public struct FrameworkMetadata: Equatable {
    public var path: AbsolutePath
    public var binaryPath: AbsolutePath
    public var dsymPath: AbsolutePath?
    public var bcsymbolmapPaths: [AbsolutePath]
    public var linking: BinaryLinking
    public var architectures: [BinaryArchitecture]
    public var status: FrameworkStatus

    public init(
        path: AbsolutePath,
        binaryPath: AbsolutePath,
        dsymPath: AbsolutePath?,
        bcsymbolmapPaths: [AbsolutePath],
        linking: BinaryLinking,
        architectures: [BinaryArchitecture],
        status: FrameworkStatus
    ) {
        self.path = path
        self.binaryPath = binaryPath
        self.dsymPath = dsymPath
        self.bcsymbolmapPaths = bcsymbolmapPaths
        self.linking = linking
        self.architectures = architectures
        self.status = status
    }
}
