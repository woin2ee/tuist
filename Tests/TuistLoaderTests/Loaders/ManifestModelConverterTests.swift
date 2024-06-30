import Foundation
import Path
import TuistCore
import TuistSupport
import XCTest

@testable import ProjectDescription
@testable import TuistCoreTesting
@testable import TuistLoader
@testable import TuistLoaderTesting
@testable import TuistSupportTesting

class ManifestModelConverterTests: TuistUnitTestCase {
    typealias WorkspaceManifest = ProjectDescription.Workspace
    typealias ProjectManifest = ProjectDescription.Project
    typealias DependenciesGraphManifest = TuistCore.DependenciesGraph
    typealias TargetManifest = ProjectDescription.Target
    typealias SettingsManifest = ProjectDescription.Settings
    typealias ConfigurationManifest = ProjectDescription.Configuration
    typealias HeadersManifest = ProjectDescription.Headers
    typealias SchemeManifest = ProjectDescription.Scheme
    typealias BuildActionManifest = ProjectDescription.BuildAction
    typealias TestActionManifest = ProjectDescription.TestAction
    typealias RunActionManifest = ProjectDescription.RunAction
    typealias ArgumentsManifest = ProjectDescription.Arguments

    private var manifestLinter: MockManifestLinter!

    override func setUp() {
        super.setUp()
        manifestLinter = MockManifestLinter()
    }

    override func tearDown() {
        manifestLinter = nil
        super.tearDown()
    }

    func test_loadProject() throws {
        // Given
        let temporaryPath = try temporaryPath()
        let manifest = ProjectManifest.test(name: "SomeProject")
        let manifestLoader = makeManifestLoader(with: [
            temporaryPath: manifest,
        ])
        let subject = makeSubject(with: manifestLoader)

        // When
        let model = try subject.convert(
            manifest: manifest,
            path: temporaryPath,
            plugins: .none,
            externalDependencies: [:],
            isExternal: false
        )

        // Then
        XCTAssertEqual(model.name, "SomeProject")
    }

    func test_loadProject_withTargets() throws {
        // Given
        let temporaryPath = try temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        let targetA = TargetManifest.test(name: "A", sources: [], resources: [])
        let targetB = TargetManifest.test(name: "B", sources: [], resources: [])
        let manifest = ProjectManifest.test(
            name: "Project",
            targets: [
                targetA,
                targetB,
            ]
        )
        let manifestLoader = makeManifestLoader(with: [
            temporaryPath: manifest,
        ])
        let subject = makeSubject(with: manifestLoader)

        // When
        let model = try subject.convert(
            manifest: manifest,
            path: temporaryPath,
            plugins: .none,
            externalDependencies: [:],
            isExternal: false
        )

        // Then
        XCTAssertEqual(model.targets.count, 2)
        try XCTAssertTargetMatchesManifest(
            target: try XCTUnwrap(model.targets["A"]),
            matches: targetA,
            at: temporaryPath,
            generatorPaths: generatorPaths
        )
        try XCTAssertTargetMatchesManifest(
            target: try XCTUnwrap(model.targets["B"]),
            matches: targetB,
            at: temporaryPath,
            generatorPaths: generatorPaths
        )
    }

    func test_loadProject_withAdditionalFiles() throws {
        // Given
        let temporaryPath = try temporaryPath()
        let files = try createFiles([
            "Documentation/README.md",
            "Documentation/guide.md",
        ])
        let manifest = ProjectManifest.test(
            name: "SomeProject",
            additionalFiles: [
                "Documentation/**/*.md",
            ]
        )
        let manifestLoader = makeManifestLoader(with: [
            temporaryPath: manifest,
        ])
        let subject = makeSubject(with: manifestLoader)

        // When
        let model = try subject.convert(
            manifest: manifest,
            path: temporaryPath,
            plugins: .none,
            externalDependencies: [:],
            isExternal: false
        )

        // Then
        XCTAssertEqual(model.additionalFiles, files.map { .file(path: $0) })
    }

    func test_loadProject_withFolderReferences() throws {
        // Given
        let temporaryPath = try temporaryPath()
        let files = try createFolders([
            "Stubs",
        ])
        let manifest = ProjectManifest.test(
            name: "SomeProject",
            additionalFiles: [
                .folderReference(path: "Stubs"),
            ]
        )
        let manifestLoader = makeManifestLoader(with: [
            temporaryPath: manifest,
        ])
        let subject = makeSubject(with: manifestLoader)

        // When
        let model = try subject.convert(
            manifest: manifest,
            path: temporaryPath,
            plugins: .none,
            externalDependencies: [:],
            isExternal: false
        )

        // Then
        XCTAssertEqual(model.additionalFiles, files.map { .folderReference(path: $0) })
    }

    func test_loadProject_withCustomOrganizationName() throws {
        // Given
        let temporaryPath = try temporaryPath()
        let manifest = ProjectManifest.test(
            name: "SomeProject",
            organizationName: "SomeOrganization",
            additionalFiles: [
                .folderReference(path: "Stubs"),
            ]
        )
        let manifestLoader = makeManifestLoader(with: [
            temporaryPath: manifest,
        ])
        let subject = makeSubject(with: manifestLoader)

        // When
        let model = try subject.convert(
            manifest: manifest,
            path: temporaryPath,
            plugins: .none,
            externalDependencies: [:],
            isExternal: false
        )

        // Then
        XCTAssertEqual(model.organizationName, "SomeOrganization")
    }

    func test_loadWorkspace() throws {
        // Given
        let temporaryPath = try temporaryPath()
        let manifest = WorkspaceManifest.test(name: "SomeWorkspace")
        let manifestLoader = makeManifestLoader(with: [
            temporaryPath: manifest,
        ])
        let subject = makeSubject(with: manifestLoader)

        // When
        let model = try subject.convert(manifest: manifest, path: temporaryPath)

        // Then
        XCTAssertEqual(model.name, "SomeWorkspace")
        XCTAssertEqual(model.projects, [])
    }

    func test_loadWorkspace_withProjects() throws {
        // Given
        let temporaryPath = try temporaryPath()
        let projects = try createFolders([
            "A",
            "B",
        ])

        let manifest = WorkspaceManifest.test(name: "SomeWorkspace", projects: ["A", "B"])
        let manifests = [
            temporaryPath: manifest,
        ]

        let manifestLoader = makeManifestLoader(with: manifests, projects: projects)
        let subject = makeSubject(with: manifestLoader)

        // When
        let model = try subject.convert(manifest: manifest, path: temporaryPath)

        // Then
        XCTAssertEqual(model.name, "SomeWorkspace")
        XCTAssertEqual(model.projects, projects)
    }

    func test_loadWorkspace_withAdditionalFiles() throws {
        let temporaryPath = try temporaryPath()
        let files = try createFiles([
            "Documentation/README.md",
            "Documentation/setup/README.md",
            "Playground.playground",
        ])

        let manifest = WorkspaceManifest.test(
            name: "SomeWorkspace",
            projects: [],
            additionalFiles: [
                "Documentation/**/*.md",
                "*.playground",
            ]
        )

        let manifestLoader = makeManifestLoader(with: [
            temporaryPath: manifest,
        ])

        let subject = makeSubject(with: manifestLoader)

        // When
        let model = try subject.convert(manifest: manifest, path: temporaryPath)

        // Then
        XCTAssertEqual(model.name, "SomeWorkspace")
        XCTAssertEqual(model.additionalFiles, files.map { .file(path: $0) })
    }

    func test_loadWorkspace_withFolderReferences() throws {
        let temporaryPath = try temporaryPath()
        try createFiles([
            "Documentation/README.md",
            "Documentation/setup/README.md",
        ])
        let manifest = WorkspaceManifest.test(
            name: "SomeWorkspace",
            projects: [],
            additionalFiles: [
                .folderReference(path: "Documentation"),
            ]
        )
        let manifestLoader = makeManifestLoader(with: [
            temporaryPath: manifest,
        ])
        let subject = makeSubject(with: manifestLoader)

        // When
        let model = try subject.convert(manifest: manifest, path: temporaryPath)

        // Then
        XCTAssertEqual(model.name, "SomeWorkspace")
        XCTAssertEqual(model.additionalFiles, [
            .folderReference(path: temporaryPath.appending(try RelativePath(validating: "Documentation"))),
        ])
    }

    func test_loadWorkspace_withInvalidProjectsPaths() throws {
        // Given
        let temporaryPath = try temporaryPath()
        let manifest = WorkspaceManifest.test(name: "SomeWorkspace", projects: ["A", "B"])
        let manifestLoader = makeManifestLoader(with: [
            temporaryPath: manifest,
        ])
        let subject = makeSubject(with: manifestLoader)

        // When
        let model = try subject.convert(manifest: manifest, path: temporaryPath)

        // Then
        XCTAssertPrinterOutputContains("""
        No projects found at: A
        No projects found at: B
        """)
        XCTAssertEqual(model.projects, [])
    }

    func test_loadDependenciesGraph_withExternalSPM() throws {
        // Given
        let temporaryPath = try temporaryPath()
        try fileHandler.createFolder(temporaryPath.appending(components: ["checkouts", "Alamofire", "Source"]))
        let manifest = DependenciesGraphManifest.alamofire(spmFolder: .path(temporaryPath.pathString))
        let subject = makeSubject(with: makeManifestLoader())

        // When
        let model = try subject.convert(manifest: manifest, path: temporaryPath)

        // Then
        XCTAssertEqual(model.externalProjects.values.first?.isExternal, true)
    }

    func test_loadDependenciesGraph_withLocalSPM() throws {
        // Given
        let temporaryPath = try temporaryPath()
        try fileHandler.createFolder(temporaryPath.appending(components: ["ADependency", "Sources", "ALibrary"]))
        try fileHandler.createFolder(temporaryPath.appending(components: ["ADependency", "Sources", "ALibraryUtils"]))
        let manifest = DependenciesGraphManifest.aDependency(spmFolder: .path(temporaryPath.pathString))
        let subject = makeSubject(with: makeManifestLoader())

        // When
        let model = try subject.convert(manifest: manifest, path: temporaryPath)

        // Then
        XCTAssertEqual(model.externalProjects.values.first?.isExternal, false)
    }
}

// MARK: - Helpers

extension ManifestModelConverterTests {
    func makeSubject(with manifestLoader: ManifestLoading) -> ManifestModelConverter {
        ManifestModelConverter(
            manifestLoader: manifestLoader
        )
    }

    func makeManifestLoader(
        with projects: [AbsolutePath: ProjectDescription.Project] = [:],
        configs: [AbsolutePath: ProjectDescription.Config] = [:]
    ) -> ManifestLoading {
        let manifestLoader = MockManifestLoader()
        manifestLoader.loadProjectStub = { path in
            guard let manifest = projects[path] else {
                throw ManifestLoaderError.manifestNotFound(path)
            }
            return manifest
        }
        manifestLoader.loadConfigStub = { path in
            guard let manifest = configs[path] else {
                throw ManifestLoaderError.manifestNotFound(path)
            }
            return manifest
        }
        manifestLoader.manifestsAtStub = { path in
            var manifests = Set<Manifest>()
            if projects[path] != nil {
                manifests.insert(.project)
            }

            if configs[path] != nil {
                manifests.insert(.config)
            }
            return manifests
        }
        return manifestLoader
    }

    func makeManifestLoader(
        with workspaces: [AbsolutePath: ProjectDescription.Workspace],
        projects: [AbsolutePath] = []
    ) -> ManifestLoading {
        let manifestLoader = MockManifestLoader()
        manifestLoader.loadWorkspaceStub = { path in
            guard let manifest = workspaces[path] else {
                throw ManifestLoaderError.manifestNotFound(path)
            }
            return manifest
        }
        manifestLoader.manifestsAtStub = { path in
            projects.contains(path) ? Set([.project]) : Set([])
        }
        return manifestLoader
    }

    private func resolveProjectPath(
        projectPath: Path?,
        defaultPath: AbsolutePath,
        generatorPaths: GeneratorPaths
    ) throws -> AbsolutePath {
        if let projectPath { return try generatorPaths.resolve(path: projectPath) }
        return defaultPath
    }
}
