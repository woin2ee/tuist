import Foundation
@testable import TuistGenerator

final class MockXcodeProjWriter: XcodeProjWriting {
    var estimatedWrittingTime: TimeInterval = 1
    
    var writeProjectCalls: [ProjectDescriptor] = []
    func write(project: ProjectDescriptor) throws {
        DispatchQueue.global().asyncAfter(deadline: .now() + estimatedWrittingTime) {
            self.writeProjectCalls.append(project)
        }
    }

    var writeworkspaceCalls: [WorkspaceDescriptor] = []
    func write(workspace: WorkspaceDescriptor) throws {
        DispatchQueue.global().asyncAfter(deadline: .now() + estimatedWrittingTime) {
            self.writeworkspaceCalls.append(workspace)
        }
    }
}
