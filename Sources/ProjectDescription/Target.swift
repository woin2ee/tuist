/// A target of a project.
public struct Target: Codable, Equatable, Sendable {
    /// The name of the target. Also, the product name if not specified with ``productName``.
    public var name: String

    /// The destinations this target supports, e.g. iPhone, appleVision, macCatalyst
    public var destinations: Destinations

    /// The type of build product this target will output.
    public var product: Product

    /// The built product name. If nil, it will be equal to ``name``.
    public var productName: String?

    /// The product bundle identifier.
    public var bundleId: String

    /// The minimum deployment targets your product will support.
    public var deploymentTargets: DeploymentTargets?

    /// The Info.plist representation.
    public var infoPlist: InfoPlist?

    /// The source files of the target.
    /// Note: any playgrounds matched by the globs used in this property will be automatically added.
    public var sources: SourceFilesList?

    /// The resource files of target.
    /// Note: localizable files, `*.lproj`, are supported.
    public var resources: ResourceFileElements?

    /// The build phase copy files actions for the target.
    public var copyFiles: [CopyFilesAction]?

    /// The headers for the target.
    public var headers: Headers?

    /// The entitlements representation
    public var entitlements: Entitlements?

    /// The build phase scripts actions for the target.
    public var scripts: [TargetScript]

    /// The target's dependencies.
    public var dependencies: [TargetDependency]

    /// The target's settings.
    public var settings: Settings?

    /// The Core Data models.
    public var coreDataModels: [CoreDataModel]

    /// The environment variables. Used by autogenerated schemes for the target.
    public var environmentVariables: [String: EnvironmentVariable]

    /// The launch arguments. Used by autogenerated schemes for the target.
    public var launchArguments: [LaunchArgument]

    /// The additional files for the target. For project's additional files, see ``Project/additionalFiles``.
    public var additionalFiles: [FileElement]

    /// The build rules used for transformation of source files during compilation.
    public var buildRules: [BuildRule]

    /// Specifies whether if the target can merge or not the dynamic dependencies as part of its binary
    public var mergedBinaryType: MergedBinaryType

    /// Specifies whether if the target can be merged as part of another binary or not
    public var mergeable: Bool

    /// The target's tags associated with on demand resources
    public var onDemandResourcesTags: OnDemandResourcesTags?

    public static func target(
        name: String,
        destinations: Destinations,
        product: Product,
        productName: String? = nil,
        bundleId: String,
        deploymentTargets: DeploymentTargets? = nil,
        infoPlist: InfoPlist? = .default,
        sources: SourceFilesList? = nil,
        resources: ResourceFileElements? = nil,
        copyFiles: [CopyFilesAction]? = nil,
        headers: Headers? = nil,
        entitlements: Entitlements? = nil,
        scripts: [TargetScript] = [],
        dependencies: [TargetDependency] = [],
        settings: Settings? = nil,
        coreDataModels: [CoreDataModel] = [],
        environmentVariables: [String: EnvironmentVariable] = [:],
        launchArguments: [LaunchArgument] = [],
        additionalFiles: [FileElement] = [],
        buildRules: [BuildRule] = [],
        mergedBinaryType: MergedBinaryType = .disabled,
        mergeable: Bool = false,
        onDemandResourcesTags: OnDemandResourcesTags? = nil
    ) -> Self {
        self.init(
            name: name,
            destinations: destinations,
            product: product,
            productName: productName,
            bundleId: bundleId,
            deploymentTargets: deploymentTargets,
            infoPlist: infoPlist,
            sources: sources,
            resources: resources,
            copyFiles: copyFiles,
            headers: headers,
            entitlements: entitlements,
            scripts: scripts,
            dependencies: dependencies,
            settings: settings,
            coreDataModels: coreDataModels,
            environmentVariables: environmentVariables,
            launchArguments: launchArguments,
            additionalFiles: additionalFiles,
            buildRules: buildRules,
            mergedBinaryType: mergedBinaryType,
            mergeable: mergeable,
            onDemandResourcesTags: onDemandResourcesTags
        )
    }
}
