import TSCBasic
import TuistLoaderTesting
import TuistGraph
import XCTest

@testable import TuistCoreTesting
@testable import TuistGeneratorTesting
@testable import TuistGraphTesting
@testable import TuistKit
@testable import TuistSupportTesting

final class GeneratorTests: TuistUnitTestCase {
    var subject: Generator!
    var swiftPackageManagerInteractor: MockSwiftPackageManagerInteractor!
    var xcodeProjWriter: MockXcodeProjWriter!
    var generator: MockDescriptorGenerator!
    var manifestGraphLoader: MockManifestGraphLoader!
    
    override func setUp() {
        super.setUp()
        swiftPackageManagerInteractor = MockSwiftPackageManagerInteractor()
        xcodeProjWriter = MockXcodeProjWriter()
        generator = MockDescriptorGenerator()
        manifestGraphLoader = MockManifestGraphLoader()
        subject = Generator(
            manifestLoader: MockManifestLoader(),
            manifestGraphLoader: manifestGraphLoader,
            generator: generator,
            writer: xcodeProjWriter,
            swiftPackageManagerInteractor: swiftPackageManagerInteractor,
            fileHandler: fileHandler
        )
    }

    override func tearDown() {
        subject = nil
        swiftPackageManagerInteractor = nil
        xcodeProjWriter = nil
        generator = nil
        manifestGraphLoader = nil
        super.tearDown()
    }
    
    func test_ifCalledInstall_afterWorkspaceWriteCompleted() async throws {
        // Given
        let temporaryDirectory = try temporaryPath()
        let workspaceName = "Test.xcworkspace"
        manifestGraphLoader.stubLoadGraph = Graph.test(path: temporaryDirectory, workspace: Workspace.test(name: workspaceName))
        generator.generateWorkspaceStub = { _ in
            .test(xcworkspacePath: temporaryDirectory.appending(component: workspaceName))
        }
        try createFiles(["\(workspaceName)/xcshareddata/swiftpm/Package.resolved"])
        
        // When
        _ = try await subject.generate(path: temporaryDirectory)
        
        // Then
        XCTAssertEqual(xcodeProjWriter.writeworkspaceCalls.count, 1)
        XCTAssertEqual(swiftPackageManagerInteractor.invokedInstallCount, 1)
    }
}
