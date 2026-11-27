import Foundation
import Vapor

/// Mock Server 的 HTTP 层。
///
/// 分两层：
/// - `respond(to:configuration:store:)` 是不依赖 Vapor 的纯分发，测试可直接调用；
/// - `make(...)` / `run(...)` 负责装配 Vapor、注册路由与监听端口。
public enum MockServerApplication {
    /// 纯分发：把请求快照变成响应，不经过 Vapor。
    ///
    /// 延迟不在这里实现，避免单测变慢；Vapor 路由层负责 sleep。
    public static func respond(
        to request: MockRequest,
        configuration: ServerConfiguration,
        store: FixtureStore
    ) -> MockHTTPResponse {
        if let failure = RequestValidator.bodyLimitFailure(byteCount: request.body.count, limit: configuration.maxBodyBytes) {
            return .failure(status: 400, message: failure)
        }

        switch RequestRouter().route(method: request.method, url: request.url) {
        case .preflight:
            return MockHTTPResponse(status: 204, headers: MockHTTPResponse.defaultJSONHeaders, body: Data())

        case .serverInfo:
            return .json(serverInfo(delayMilliseconds: configuration.delayMilliseconds))

        case .health:
            return .json(healthPayload(configuration: configuration, store: store))

        case .rpc:
            switch MockRPCService.handle(body: request.body, store: store) {
            case let .success(result):
                return .raw(result.body)
            case let .failure(error):
                return .failure(status: 400, message: error.message)
            }

        case .proxy:
            let router = FixtureRouter(store: store)
            let (response, _) = router.respond(to: request)
            return response

        case .unsupported:
            return .failure(
                status: 404,
                message: "not found: \(request.method) \(request.path)"
            )
        }
    }

    /// `GET /` 的服务信息。
    public static func serverInfo(delayMilliseconds: Int) -> JSONValue {
        .object([
            "name": .string("mihoyo-tool-mock-service"),
            "rpc": .string("POST /__mock/rpc"),
            "health": .string("GET /__health"),
            "delayMs": .int(delayMilliseconds),
        ])
    }

    /// `GET /__health` 的健康检查。
    ///
    /// `fixtures` 是递归统计的 `.json` 数量，便于确认读到了正确目录。
    public static func healthPayload(configuration: ServerConfiguration, store: FixtureStore) -> JSONValue {
        .object([
            "ok": .bool(true),
            "fixtures": .int(store.count()),
            "delayMs": .int(configuration.delayMilliseconds),
            "fixturesDir": .string(store.root.path),
        ])
    }

    /// 装配 Vapor 应用并注册全部路由。
    ///
    /// 参数只用 `serve`，避免把自定义的 `--fixtures` 等参数交给 Vapor 的命令解析。
    public static func make(configuration: ServerConfiguration, store: FixtureStore) throws -> Application {
        let environment = Environment(name: "production", arguments: ["mock-server", "serve"])
        let app = Application(environment)

        app.http.server.configuration.hostname = configuration.host
        app.http.server.configuration.port = configuration.port
        app.routes.defaultMaxBodySize = "8mb"
        app.logger.logLevel = .info

        /// 共用的处理入口：快照请求 → 可选延迟 → 分发 → 转 Vapor Response。
        func handle(_ request: Request) async throws -> Response {
            if configuration.delayMilliseconds > 0 {
                try await Task.sleep(nanoseconds: UInt64(configuration.delayMilliseconds) * 1_000_000)
            }

            let snapshot = makeSnapshot(from: request)
            let mockResponse = respond(to: snapshot, configuration: configuration, store: store)

            if let route = fixtureLogDescription(snapshot: snapshot, store: store, configuration: configuration) {
                app.logger.info("\(request.method.rawValue) \(snapshot.path) -> \(route)")
            }

            return makeVaporResponse(mockResponse)
        }

        // 根路径单独注册：catchall 不匹配空路径。
        app.get { request async throws -> Response in
            try await handle(request)
        }
        app.on(.GET, .catchall) { request async throws -> Response in
            try await handle(request)
        }
        app.on(.POST, .catchall) { request async throws -> Response in
            try await handle(request)
        }
        app.on(.OPTIONS, .catchall) { request async throws -> Response in
            try await handle(request)
        }
        app.on(.OPTIONS) { request async throws -> Response in
            try await handle(request)
        }

        return app
    }

    /// 启动并阻塞运行。
    public static func run(configuration: ServerConfiguration, store: FixtureStore) throws {
        let app = try make(configuration: configuration, store: store)
        defer { app.shutdown() }

        app.logger.info("listening on http://\(configuration.host):\(configuration.port)")
        app.logger.info("fixtures: \(store.count()) (\(store.root.path))")
        app.logger.info("delay: \(configuration.delayMilliseconds)ms")
        if configuration.host == "127.0.0.1" || configuration.host == "localhost" {
            app.logger.info("真机/模拟器请先执行: hdc rport tcp:\(configuration.port) tcp:\(configuration.port)")
        }

        try app.run()
    }

    /// Vapor `Request` → 框架无关快照。
    static func makeSnapshot(from request: Request) -> MockRequest {
        var url = request.url.path
        if url.isEmpty { url = "/" }
        if let query = request.url.query, !query.isEmpty {
            url += "?" + query
        }

        var headers: [String: String] = [:]
        for header in request.headers {
            headers[header.name] = header.value
        }

        let body = request.body.data.map { Data(buffer: $0) } ?? Data()

        return MockRequest(
            method: request.method.rawValue,
            url: url,
            headers: headers,
            body: body,
            remoteAddress: request.remoteAddress?.ipAddress
        )
    }

    /// 把核心层响应转成 Vapor 响应。
    static func makeVaporResponse(_ response: MockHTTPResponse) -> Response {
        var headers = HTTPHeaders()
        for (name, value) in response.headers {
            headers.add(name: name, value: value)
        }
        return Response(
            status: HTTPResponseStatus(statusCode: response.status),
            headers: headers,
            body: .init(data: response.body)
        )
    }

    /// 生成一行日志：命中哪个 fixture，或走了哪个内置端点。
    ///
    /// 只在 `/__health` 之外的请求上调用，避免健康检查刷屏。
    static func fixtureLogDescription(
        snapshot: MockRequest,
        store: FixtureStore,
        configuration: ServerConfiguration
    ) -> String? {
        switch RequestRouter().route(method: snapshot.method, url: snapshot.url) {
        case .preflight:
            return nil
        case .serverInfo:
            return "serverInfo"
        case .health:
            return nil
        case .rpc:
            return "rpc"
        case .unsupported:
            return "unsupported"
        case .proxy:
            let lookup = store.lookup(FixtureQuery(path: snapshot.url, cookie: snapshot.cookie))
            return lookup.file ?? "empty"
        }
    }
}
