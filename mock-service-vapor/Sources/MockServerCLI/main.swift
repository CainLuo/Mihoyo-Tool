import Darwin
import Foundation
import MockServerCore

/// `mock-server` 命令行入口。
///
/// 职责只有三件事：解析参数、校验 fixtures 目录、启动服务。
/// 所有业务逻辑都在 `MockServerCore`，便于单测。
let rawArguments = Array(CommandLine.arguments.dropFirst())

if rawArguments.contains("--help") || rawArguments.contains("-h") {
    print(ServerConfiguration.usage)
    exit(0)
}

let configuration = ServerConfiguration.from(arguments: CommandLine.arguments)
let store = FixtureStore(root: configuration.fixturesDirectory)

guard store.exists else {
    let message = """
    找不到 fixtures 目录: \(store.root.path)
    请用 --fixtures <目录> 指定，或在仓库内启动（默认复用 mock-service/fixtures）。
    """
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

do {
    try MockServerApplication.run(configuration: configuration, store: store)
} catch {
    let message = "启动失败: \(error)\n"
    FileHandle.standardError.write(Data(message.utf8))
    exit(1)
}
