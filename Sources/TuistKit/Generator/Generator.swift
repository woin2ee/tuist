import Foundation
import ProjectDescription
import TSCBasic
import TuistCore
import TuistDependencies
import TuistGenerator
import TuistGraph
import TuistLoader
import TuistPlugin
import TuistSupport

public protocol Generating {
    @discardableResult
    func load(path: AbsolutePath) async throws -> Graph
    func generate(path: AbsolutePath) async throws -> AbsolutePath
    func generateWithGraph(path: AbsolutePath) async throws -> (AbsolutePath, Graph)
}

public class Generator: Generating {
    private let graphLinter: GraphLinting = GraphLinter()
    private let environmentLinter: EnvironmentLinting = EnvironmentLinter()
    private let generator: DescriptorGenerating
    private let writer: XcodeProjWriting
    private let swiftPackageManagerInteractor: TuistGenerator.SwiftPackageManagerInteracting
    private let sideEffectDescriptorExecutor: SideEffectDescriptorExecuting
    private let configLoader: ConfigLoading
    private let manifestGraphLoader: ManifestGraphLoading
    private var lintingIssues: [LintingIssue] = []
    private let fileHandler: FileHandling

    public init(
        manifestLoader: ManifestLoading,
        manifestGraphLoader: ManifestGraphLoading,
        generator: DescriptorGenerating = DescriptorGenerator(),
        writer: XcodeProjWriting = XcodeProjWriter(),
        swiftPackageManagerInteractor: SwiftPackageManagerInteracting = SwiftPackageManagerInteractor(),
        fileHandler: FileHandling = FileHandler.shared
    ) {
        sideEffectDescriptorExecutor = SideEffectDescriptorExecutor()
        configLoader = ConfigLoader(
            manifestLoader: manifestLoader,
            rootDirectoryLocator: RootDirectoryLocator(),
            fileHandler: FileHandler.shared
        )
        self.manifestGraphLoader = manifestGraphLoader
        self.generator = generator
        self.writer = writer
        self.swiftPackageManagerInteractor = swiftPackageManagerInteractor
        self.fileHandler = fileHandler
    }

    public func generate(path: AbsolutePath) async throws -> AbsolutePath {
        let (generatedPath, _) = try await generateWithGraph(path: path)
        return generatedPath
    }

    public func generateWithGraph(path: AbsolutePath) async throws -> (AbsolutePath, Graph) {
        let (graph, sideEffects) = try await load(path: path)

        // Load
        let graphTraverser = GraphTraverser(graph: graph)

        // Lint
        try lint(graphTraverser: graphTraverser)

        // Generate
        let workspaceDescriptor = try generator.generateWorkspace(graphTraverser: graphTraverser)

        // packageResolvedWatcher.setUp()
        let workspacePackageResolvedPath = graphTraverser.path
            .appending(component: workspaceDescriptor.xcworkspacePath.basename)
            .appending(try RelativePath(validating: "xcshareddata/swiftpm/Package.resolved"))
        try fileHandler.touch(workspacePackageResolvedPath)
        
        // Write
        try writer.write(workspace: workspaceDescriptor)

        // Mapper side effects
        try sideEffectDescriptorExecutor.execute(sideEffects: sideEffects)

        // Post Generate Actions
        try await postGenerationActions(
            graphTraverser: graphTraverser,
            workspaceName: workspaceDescriptor.xcworkspacePath.basename
        )

        printAndFlushPendingLintWarnings()

        return (workspaceDescriptor.xcworkspacePath, graph)
    }

    public func load(path: AbsolutePath) async throws -> Graph {
        try await load(path: path).0
    }

    func load(path: AbsolutePath) async throws -> (Graph, [SideEffectDescriptor]) {
        logger.notice("Loading and constructing the graph", metadata: .section)
        logger.notice("It might take a while if the cache is empty")

        let (graph, sideEffectDescriptors, issues) = try await manifestGraphLoader.load(path: path)

        lintingIssues.append(contentsOf: issues)
        return (graph, sideEffectDescriptors)
    }

    private func lint(graphTraverser: GraphTraversing) throws {
        let config = try configLoader.loadConfig(path: graphTraverser.path)

        let environmentIssues = try environmentLinter.lint(config: config)
        try environmentIssues.printAndThrowErrorsIfNeeded()
        lintingIssues.append(contentsOf: environmentIssues)

        let graphIssues = graphLinter.lint(graphTraverser: graphTraverser, config: config)
        try graphIssues.printAndThrowErrorsIfNeeded()
        lintingIssues.append(contentsOf: graphIssues)
    }

    private func postGenerationActions(graphTraverser: GraphTraversing, workspaceName: String) async throws {
        let config = try configLoader.loadConfig(path: graphTraverser.path)

        let workspacePath = graphTraverser.path.appending(component: workspaceName)
        try waitWorkspaceWritten(path: workspacePath)
        
        // PackageResolvedWatcher
        // try await packageResolvedWatcher.waitWorkspaceWritten(path: workspacePath)
        
        try await swiftPackageManagerInteractor.install(
            graphTraverser: graphTraverser,
            workspaceName: workspaceName,
            config: config
        )
    }

    private func printAndFlushPendingLintWarnings() {
        // Print out warnings, if any
        lintingIssues.printWarningsIfNeeded()
        lintingIssues.removeAll()
    }
    
    private func waitWorkspaceWritten(path workspacePath: AbsolutePath) throws {
        // The existence of the `Package.resolved` file determines if the `workspace` write is complete.
        let workspacePackageResolvedPath = workspacePath
            .appending(try RelativePath(validating: "xcshareddata/swiftpm/Package.resolved"))

        var isTimeout = false
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            isTimeout = true
        }
        
        var repeatCount = 0
        while true {
            if isTimeout || !fileHandler.exists(workspacePackageResolvedPath) {
                print(repeatCount)
                return
            }
            repeatCount += 1
        }
        
//        while !isTimeout && fileHandler.exists(workspacePackageResolvedPath) {}
    }
}
