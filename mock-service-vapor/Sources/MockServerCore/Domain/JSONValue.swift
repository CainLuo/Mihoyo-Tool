import Foundation

/// 一个与框架解耦的 JSON 值。
///
/// 之所以不直接用 `Codable` 结构体：fixture 有 224 份、字段随游戏版本变化，
/// 用强类型会把 mock 服务变成需要跟着游戏更新而改代码的负担。
/// 这里只做「解析 → 取字段 / 编码」两件事，保留原始数值类型（整数不写成 1.0）。
public enum JSONValue: Equatable, Sendable {
    /// JSON `null`。
    case null
    /// JSON 布尔值。
    case bool(Bool)
    /// JSON 整数。游戏数据里 retcode、等级、数量都是整数，单独保留以免被写成浮点。
    case int(Int)
    /// JSON 浮点数。命中率、暴击率等小数值走这里。
    case number(Double)
    /// JSON 字符串。
    case string(String)
    /// JSON 数组，保持原始顺序。
    case array([JSONValue])
    /// JSON 对象。键顺序对 mock 响应无影响，对 fixture 原样返回由 `Fixture.data` 保证。
    case object([String: JSONValue])
}

public extension JSONValue {
    /// 从 `Data` 解析 JSON。空数据或非法 JSON 会抛错，调用方可据此回退到空响应。
    init(parsing data: Data) throws {
        let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        self = JSONValue(any: object)
    }

    /// 从字符串解析 JSON。
    init(parsing text: String) throws {
        try self.init(parsing: Data(text.utf8))
    }

    /// 把任意 `JSONSerialization` 产物转换成 `JSONValue`。
    ///
    /// 关键点：`NSNumber` 同时承载布尔与数值，这里用 `CFBoolean` 的类型判断区分，
    /// 再把整数值的 Double 收回 `.int`，避免 `retcode` 被编码成 `0.0`。
    init(any value: Any) {
        switch value {
        case is NSNull:
            self = .null
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                self = .bool(number.boolValue)
            } else {
                let double = number.doubleValue
                if double == double.rounded(), abs(double) <= 9_007_199_254_740_992 {
                    self = .int(number.intValue)
                } else {
                    self = .number(double)
                }
            }
        case let string as String:
            self = .string(string)
        case let array as [Any]:
            self = .array(array.map(JSONValue.init(any:)))
        case let dictionary as [String: Any]:
            self = .object(dictionary.mapValues(JSONValue.init(any:)))
        default:
            self = .string(String(describing: value))
        }
    }

    /// 编码成 JSON 数据。
    ///
    /// `sortedKeys` 让合成响应的字节稳定，便于测试断言；fixture 原样返回时不走这里。
    func encoded(sortedKeys: Bool = true) throws -> Data {
        // `fragmentsAllowed` 允许顶层直接是标量或 null（RPC 回显、调试接口会用到）。
        var options: JSONSerialization.WritingOptions = [.fragmentsAllowed, .withoutEscapingSlashes]
        if sortedKeys {
            options.insert(.sortedKeys)
        }
        return try JSONSerialization.data(withJSONObject: anyValue, options: options)
    }

    /// 递归还原成 `JSONSerialization` 可接受的容器类型。
    var anyValue: Any {
        switch self {
        case .null:
            return NSNull()
        case let .bool(value):
            return value
        case let .int(value):
            return value
        case let .number(value):
            return value
        case let .string(value):
            return value
        case let .array(values):
            return values.map(\.anyValue)
        case let .object(values):
            return values.mapValues(\.anyValue)
        }
    }

    /// 对象取字段；非对象返回 nil。
    subscript(key: String) -> JSONValue? {
        guard case let .object(values) = self else { return nil }
        return values[key]
    }

    /// 整数值。同时兼容 `.int` 与整数值的 `.number`（真实 API 偶尔返回 `0.0`）。
    var intValue: Int? {
        switch self {
        case let .int(value):
            return value
        case let .number(value) where value == value.rounded():
            return Int(value)
        case let .string(value):
            return Int(value)
        default:
            return nil
        }
    }

    /// 字符串值。数字按 JS 的 `String(number)` 习惯输出，整数值不带 `.0`。
    var stringValue: String? {
        switch self {
        case let .string(value):
            return value
        case let .int(value):
            return String(value)
        case let .number(value):
            if value == value.rounded(), abs(value) <= 9_007_199_254_740_992 {
                return String(Int(value))
            }
            return String(value)
        case let .bool(value):
            return value ? "true" : "false"
        default:
            return nil
        }
    }

    /// 布尔值。
    var boolValue: Bool? {
        if case let .bool(value) = self { return value }
        return nil
    }

    /// 数组值。
    var arrayValue: [JSONValue]? {
        if case let .array(values) = self { return values }
        return nil
    }

    /// 对象值。
    var objectValue: [String: JSONValue]? {
        if case let .object(values) = self { return values }
        return nil
    }

    /// 是否为 `null`。
    var isNull: Bool {
        if case .null = self { return true }
        return false
    }
}
