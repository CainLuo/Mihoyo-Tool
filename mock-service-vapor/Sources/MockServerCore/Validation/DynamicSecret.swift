import CryptoKit
import Foundation

/// 米游社请求头 `DS` 的结构：`{timestamp},{nonce},{md5}`。
///
/// mock 服务默认**不校验**签名（App 传来的仍是真实 DS），
/// 这里提供解析与生成能力，用于调试接口、日志与回归测试。
public struct DynamicSecret: Equatable, Sendable {
    /// Unix 秒级时间戳字符串，必须是纯数字。
    public var timestamp: String
    /// 6 位随机数（真实客户端取 100000...999999，测试里可自定义）。
    public var nonce: String
    /// 32 位小写十六进制 MD5。
    public var value: String

    public init(timestamp: String, nonce: String, value: String) {
        self.timestamp = timestamp
        self.nonce = nonce
        self.value = value
    }

    /// 解析 `1700000000,123456,ea56f3c12b77bcd23947635b9b4634f3`。
    ///
    /// 段数不为 3、时间戳/随机数非数字、摘要非 32 位小写十六进制时返回 nil。
    public static func parse(_ raw: String) -> DynamicSecret? {
        let parts = raw.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 3 else { return nil }
        let secret = DynamicSecret(timestamp: parts[0], nonce: parts[1], value: parts[2])
        return secret.isWellFormed ? secret : nil
    }

    /// 结构是否合法（不校验 MD5 是否正确）。
    public var isWellFormed: Bool {
        let digits = CharacterSet.decimalDigits
        guard !timestamp.isEmpty, timestamp.unicodeScalars.allSatisfy(digits.contains) else { return false }
        guard !nonce.isEmpty, nonce.unicodeScalars.allSatisfy(digits.contains) else { return false }
        guard value.count == 32 else { return false }
        return value.unicodeScalars.allSatisfy { scalar in
            (scalar.value >= 48 && scalar.value <= 57) || (scalar.value >= 97 && scalar.value <= 102)
        }
    }

    /// 重新拼回请求头字符串。
    public var headerValue: String {
        "\(timestamp),\(nonce),\(value)"
    }
}

/// 参与 MD5 的输入集合。
public struct DynamicSecretInput: Equatable, Sendable {
    /// 参与签名的 query，例如 `role_id=1&server=cn_gf01`。
    public var query: String
    /// Unix 秒级时间戳。
    public var timestamp: String
    /// 随机数。
    public var nonce: String
    /// 游戏对应的 salt。
    public var salt: String

    public init(query: String, timestamp: String, nonce: String, salt: String = DynamicSecretGenerator.canonicalSalt) {
        self.query = query
        self.timestamp = timestamp
        self.nonce = nonce
        self.salt = salt
    }
}

/// DS 生成器。
///
/// 规范化输入（与米游社客户端一致）：
/// `salt={salt}&{query}&t={timestamp}&r={nonce}`，
/// 对其 UTF-8 字节做 MD5，取 32 位小写十六进制。
public enum DynamicSecretGenerator {
    /// 原神（hk4e）网页端使用的 salt。
    public static let canonicalSalt = "xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs"

    /// 规范化后的待签名字符串。
    public static func canonicalInput(_ input: DynamicSecretInput) -> String {
        "salt=\(input.salt)&\(input.query)&t=\(input.timestamp)&r=\(input.nonce)"
    }

    /// 对输入求 DS。
    public static func sign(_ input: DynamicSecretInput) -> String {
        md5Hex(canonicalInput(input))
    }

    /// 便捷入口：直接给 query / 时间戳 / 随机数 / salt。
    public static func generate(
        query: String,
        timestamp: String,
        nonce: String,
        salt: String = canonicalSalt
    ) -> String {
        sign(DynamicSecretInput(query: query, timestamp: timestamp, nonce: nonce, salt: salt))
    }

    /// 校验一个已解析的 DS 是否与输入匹配。
    public static func matches(_ secret: DynamicSecret, input: DynamicSecretInput) -> Bool {
        guard secret.isWellFormed else { return false }
        guard secret.timestamp == input.timestamp, secret.nonce == input.nonce else { return false }
        return secret.value == sign(input)
    }

    /// 计算 MD5 并输出小写十六进制。
    public static func md5Hex(_ text: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(text.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
