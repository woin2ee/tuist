import TuistCore
import TuistGenerator
import TuistGraph

final class MockSwiftPackageManagerInteractor: SwiftPackageManagerInteracting {
    
    var invokedInstallCount = 0
    
    func install(graphTraverser: any GraphTraversing, workspaceName: String, config: Config) async throws {
        invokedInstallCount += 1
    }
}
