import Foundation
import Path
import TuistScaffold
import TuistSupport
import XcodeGraph
import XCTest

@testable import TuistKit
@testable import TuistLoaderTesting
@testable import TuistScaffoldTesting
@testable import TuistSupportTesting

final class InitServiceTests: TuistUnitTestCase {
    var subject: InitService!
    var templatesDirectoryLocator: MockTemplatesDirectoryLocator!
    var templateGenerator: MockTemplateGenerator!
    var templateLoader: MockTemplateLoader!
    var templateGitLoader: MockTemplateGitLoader!
    var tuistVersionLoader: MockTuistVersionLoader!

    override func setUp() {
        super.setUp()
        templatesDirectoryLocator = MockTemplatesDirectoryLocator()
        templateGenerator = MockTemplateGenerator()
        templateLoader = MockTemplateLoader()
        templateGitLoader = MockTemplateGitLoader()
        tuistVersionLoader = MockTuistVersionLoader()
        subject = InitService(
            templateLoader: templateLoader,
            templatesDirectoryLocator: templatesDirectoryLocator,
            templateGenerator: templateGenerator,
            templateGitLoader: templateGitLoader,
            tuistVersionLoader: tuistVersionLoader
        )
    }

    override func tearDown() {
        subject = nil
        templatesDirectoryLocator = nil
        templateGenerator = nil
        templateLoader = nil
        templateGitLoader = nil
        super.tearDown()
    }

    func test_fails_when_directory_not_empty() throws {
        // Given
        let path = FileHandler.shared.currentPath
        try FileHandler.shared.touch(path.appending(component: "dummy"))

        // Then
        XCTAssertThrowsSpecific(try subject.testRun(), InitServiceError.nonEmptyDirectory(path))
    }

    func test_init_fails_when_template_not_found() throws {
        let templateName = "template"
        XCTAssertThrowsSpecific(try subject.testRun(templateName: templateName), InitServiceError.templateNotFound(templateName))
    }

    func test_init_default_when_no_template() throws {
        // Given
        let defaultTemplatePath = try temporaryPath().appending(component: "default")
        templatesDirectoryLocator.templateDirectoriesStub = { _ in
            [defaultTemplatePath]
        }

        let tuistVersion = "4.0.3"
        tuistVersionLoader.getVersionStub = tuistVersion

        let expectedAttributes: [String: XcodeGraph.Template.Attribute.Value] = [
            "name": .string("Name"),
            "platform": .string("macOS"),
            "tuist_version": .string(tuistVersion),
        ]
        var generatorAttributes: [String: XcodeGraph.Template.Attribute.Value] = [:]
        templateGenerator.generateStub = { _, _, attributes in
            generatorAttributes = attributes
        }

        // When
        try subject.testRun(name: "Name", platform: "macos")

        // Then
        XCTAssertEqual(expectedAttributes, generatorAttributes)
    }

    func test_init_default_platform() throws {
        // Given
        let defaultTemplatePath = try temporaryPath().appending(component: "default")
        templatesDirectoryLocator.templateDirectoriesStub = { _ in
            [defaultTemplatePath]
        }

        let tuistVersion = "4.0.3"
        tuistVersionLoader.getVersionStub = tuistVersion

        let expectedAttributes: [String: XcodeGraph.Template.Attribute.Value] = [
            "name": .string("Name"),
            "platform": .string("iOS"),
            "tuist_version": .string(tuistVersion),
        ]
        var generatorAttributes: [String: XcodeGraph.Template.Attribute.Value] = [:]
        templateGenerator.generateStub = { _, _, attributes in
            generatorAttributes = attributes
        }

        // When
        try subject.testRun(name: "Name")

        // Then
        XCTAssertEqual(expectedAttributes, generatorAttributes)
    }

    func test_load_git_template_attributes() async throws {
        // Given
        templateGitLoader.loadTemplateStub = { _ in
            Template(
                description: "test",
                attributes: [
                    .required("required"),
                    .optional("optional", default: .string("optionalValue")),
                ],
                items: []
            )
        }

        let tuistVersion = "4.0.3"
        tuistVersionLoader.getVersionStub = tuistVersion

        let expectedAttributes: [String: XcodeGraph.Template.Attribute.Value] = [
            "name": .string("Name"),
            "platform": .string("macOS"),
            "tuist_version": .string(tuistVersion),
            "required": .string("requiredValue"),
            "optional": .string("optionalValue"),
        ]
        var generatorAttributes: [String: XcodeGraph.Template.Attribute.Value] = [:]
        templateGenerator.generateStub = { _, _, attributes in
            generatorAttributes = attributes
        }

        // When
        try subject.testRun(
            name: "Name",
            platform: "macos",
            templateName: "https://url/to/repo.git",
            requiredTemplateOptions: [
                "required": "requiredValue",
            ]
        )

        // Then
        XCTAssertEqual(expectedAttributes, generatorAttributes)
    }

    func test_optional_dictionary_attribute_is_taken_from_template() async throws {
        // Given
        let context: XcodeGraph.Template.Attribute.Value = .dictionary([
            "key1": .string("value1"),
            "key2": .string("value2"),
        ])

        templateLoader.loadTemplateStub = { _ in
            Template.test(attributes: [
                .optional("optional", default: context),
            ])
        }

        let tuistVersion = "4.0.3"
        tuistVersionLoader.getVersionStub = tuistVersion

        let defaultTemplatePath = try temporaryPath().appending(component: "default")
        templatesDirectoryLocator.templateDirectoriesStub = { _ in
            [defaultTemplatePath]
        }

        let expectedAttributes: [String: XcodeGraph.Template.Attribute.Value] = [
            "name": .string("Name"),
            "platform": .string("iOS"),
            "tuist_version": .string(tuistVersion),
            "optional": context,
        ]

        var generatorAttributes: [String: XcodeGraph.Template.Attribute.Value] = [:]
        templateGenerator.generateStub = { _, _, attributes in
            generatorAttributes = attributes
        }

        // When
        try subject.testRun(name: "Name")

        // Then
        XCTAssertEqual(expectedAttributes, generatorAttributes)
    }

    func test_optional_integer_attribute_is_taken_from_template() async throws {
        // Given
        let defaultIntegerValue: XcodeGraph.Template.Attribute.Value = .integer(999)

        templateLoader.loadTemplateStub = { _ in
            Template.test(attributes: [
                .optional("optional", default: defaultIntegerValue),
            ])
        }

        let tuistVersion = "4.0.3"
        tuistVersionLoader.getVersionStub = tuistVersion

        let defaultTemplatePath = try temporaryPath().appending(component: "default")
        templatesDirectoryLocator.templateDirectoriesStub = { _ in
            [defaultTemplatePath]
        }

        let expectedAttributes: [String: XcodeGraph.Template.Attribute.Value] = [
            "name": .string("Name"),
            "platform": .string("iOS"),
            "tuist_version": .string(tuistVersion),
            "optional": defaultIntegerValue,
        ]

        var generatorAttributes: [String: XcodeGraph.Template.Attribute.Value] = [:]
        templateGenerator.generateStub = { _, _, attributes in
            generatorAttributes = attributes
        }

        // When
        try subject.testRun(name: "Name")

        // Then
        XCTAssertEqual(expectedAttributes, generatorAttributes)
    }
}

extension InitService {
    func testRun(
        name: String? = nil,
        platform: String? = nil,
        path: String? = nil,
        templateName: String? = nil,
        requiredTemplateOptions: [String: String] = [:],
        optionalTemplateOptions: [String: String?] = [:]
    ) throws {
        try run(
            name: name,
            platform: platform,
            path: path,
            templateName: templateName,
            requiredTemplateOptions: requiredTemplateOptions,
            optionalTemplateOptions: optionalTemplateOptions
        )
    }
}
