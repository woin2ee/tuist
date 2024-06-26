import Foundation
import Path
import TuistLoader
import XcodeGraph

public final class MockTemplateGitLoader: TemplateGitLoading {
    public var loadTemplateStub: ((String) throws -> Template)?
    public func loadTemplate(from templateURL: String, closure: (Template) throws -> Void) throws {
        let template = try loadTemplateStub?(templateURL) ?? Template(description: "", attributes: [], items: [])
        try closure(template)
    }
}
