import XCTest
@testable import MockServerCore

/// `DynamicSecret` 的解析与生成。
///
/// 注意：给定向量 `1700000000,123456,ea56f3c12b77bcd23947635b9b4634f3`
/// 无法用标准公式复现（见 `docs/Design.md` 的说明），
/// 因此这里只把它当作「结构合法的样本请求头」，生成侧用独立金标校验。
final class DynamicSecretTests: XCTestCase {

    /// 场景：解析需求里给出的固定样本。
    /// 期望：能被解析成三段，结构合法。
    func testParseSampleVector() {
        let secret = DynamicSecret.parse("1700000000,123456,ea56f3c12b77bcd23947635b9b4634f3")
        XCTAssertNotNil(secret)
        XCTAssertTrue(secret?.isWellFormed ?? false)
    }

    /// 场景：解析后的字段。
    /// 期望：时间戳、随机数、摘要各自独立保存，不做类型转换。
    func testParseFields() {
        let secret = DynamicSecret.parse("1700000000,123456,ea56f3c12b77bcd23947635b9b4634f3")
        XCTAssertEqual(secret?.timestamp, "1700000000")
        XCTAssertEqual(secret?.nonce, "123456")
        XCTAssertEqual(secret?.value, "ea56f3c12b77bcd23947635b9b4634f3")
    }

    /// 场景：解析后再拼回请求头。
    /// 期望：与原始字符串完全一致（无信息丢失）。
    func testHeaderValueRoundTrip() {
        let raw = "1700000000,123456,ea56f3c12b77bcd23947635b9b4634f3"
        XCTAssertEqual(DynamicSecret.parse(raw)?.headerValue, raw)
    }

    /// 场景：段数不是 3。
    /// 期望：返回 nil，不能把畸形头当合法 DS。
    func testParseWrongPartCount() {
        XCTAssertNil(DynamicSecret.parse("1700000000,123456"))
        XCTAssertNil(DynamicSecret.parse("1700000000,123456,abc,extra"))
        XCTAssertNil(DynamicSecret.parse(""))
    }

    /// 场景：时间戳含非数字字符。
    /// 期望：返回 nil。
    func testParseNonNumericTimestamp() {
        XCTAssertNil(DynamicSecret.parse("17e8,123456,ea56f3c12b77bcd23947635b9b4634f3"))
        XCTAssertNil(DynamicSecret.parse(",-1,ea56f3c12b77bcd23947635b9b4634f3"))
    }

    /// 场景：随机数含非数字字符。
    /// 期望：返回 nil。
    func testParseNonNumericNonce() {
        XCTAssertNil(DynamicSecret.parse("1700000000,12a456,ea56f3c12b77bcd23947635b9b4634f3"))
    }

    /// 场景：摘要长度不足 32。
    /// 期望：返回 nil（MD5 必须是 32 位）。
    func testParseShortDigest() {
        XCTAssertNil(DynamicSecret.parse("1700000000,123456,ea56f3c1"))
    }

    /// 场景：摘要使用大写十六进制。
    /// 期望：被拒绝；真实客户端只发送小写，大小写混用意味着格式错误。
    func testParseUppercaseDigestRejected() {
        XCTAssertNil(DynamicSecret.parse("1700000000,123456,EA56F3C12B77BCD23947635B9B4634F3"))
    }

    /// 场景：摘要含非十六进制字符。
    /// 期望：返回 nil。
    func testParseNonHexRejected() {
        XCTAssertNil(DynamicSecret.parse("1700000000,123456,ga56f3c12b77bcd23947635b9b4634f3"))
    }

    /// 场景：时间戳为空串。
    /// 期望：`isWellFormed` 为 false（`parse` 也返回 nil）。
    func testIsWellFormedRequiresFields() {
        XCTAssertFalse(DynamicSecret(timestamp: "", nonce: "123456", value: String(repeating: "a", count: 32)).isWellFormed)
        XCTAssertFalse(DynamicSecret(timestamp: "1", nonce: "", value: String(repeating: "a", count: 32)).isWellFormed)
        XCTAssertTrue(DynamicSecret(timestamp: "1", nonce: "2", value: String(repeating: "a", count: 32)).isWellFormed)
    }

    /// 场景：时间戳带前导零、随机数很长。
    /// 期望：只校验「纯数字」，不限制长度，解析成功。
    func testParseAllowsArbitraryDigitLength() {
        let secret = DynamicSecret.parse("0001700000000,123456789012,ea56f3c12b77bcd23947635b9b4634f3")
        XCTAssertEqual(secret?.timestamp, "0001700000000")
        XCTAssertEqual(secret?.nonce, "123456789012")
    }

    /// 场景：原神网页端 salt。
    /// 期望：与客户端使用的常量一致。
    func testCanonicalSalt() {
        XCTAssertEqual(DynamicSecretGenerator.canonicalSalt, "xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs")
    }

    /// 场景：规范化待签名字符串。
    /// 期望：`salt={salt}&{query}&t={ts}&r={nonce}`，顺序固定。
    func testCanonicalInputFormat() {
        let input = DynamicSecretInput(
            query: "role_id=1&server=cn_gf01",
            timestamp: "1700000000",
            nonce: "123456"
        )
        XCTAssertEqual(
            DynamicSecretGenerator.canonicalInput(input),
            "salt=xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs&role_id=1&server=cn_gf01&t=1700000000&r=123456"
        )
    }

    /// 场景：query 为空。
    /// 期望：仍保留 `salt=...&` 与 `&t=` 两个分隔符，与客户端实现一致。
    func testCanonicalInputEmptyQuery() {
        let input = DynamicSecretInput(query: "", timestamp: "1", nonce: "2")
        XCTAssertEqual(
            DynamicSecretGenerator.canonicalInput(input),
            "salt=xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs&&t=1&r=2"
        )
    }

    /// 场景：对标准输入求 MD5。
    /// 期望：命中独立计算出的金标 `e73e9e44da8e2c0a832a481d085aba5b`。
    func testSignGoldenVector() {
        let input = DynamicSecretInput(
            query: "role_id=1&server=cn_gf01",
            timestamp: "1700000000",
            nonce: "123456"
        )
        XCTAssertEqual(DynamicSecretGenerator.sign(input), "e73e9e44da8e2c0a832a481d085aba5b")
    }

    /// 场景：`generate` 便捷入口。
    /// 期望：与 `sign(DynamicSecretInput(...))` 完全等价。
    func testGenerateEqualsSign() {
        XCTAssertEqual(
            DynamicSecretGenerator.generate(
                query: "role_id=1&server=cn_gf01",
                timestamp: "1700000000",
                nonce: "123456"
            ),
            DynamicSecretGenerator.sign(
                DynamicSecretInput(
                    query: "role_id=1&server=cn_gf01",
                    timestamp: "1700000000",
                    nonce: "123456"
                )
            )
        )
    }

    /// 场景：自洽校验——用生成的 DS 去匹配同一输入。
    /// 期望：`matches` 返回 true。
    func testMatchesTrue() {
        let input = DynamicSecretInput(query: "role_id=1", timestamp: "1700000000", nonce: "123456")
        let secret = DynamicSecret(
            timestamp: input.timestamp,
            nonce: input.nonce,
            value: DynamicSecretGenerator.sign(input)
        )
        XCTAssertTrue(DynamicSecretGenerator.matches(secret, input: input))
    }

    /// 场景：时间戳或随机数与输入不一致。
    /// 期望：`matches` 返回 false（即使摘要恰好相同）。
    func testMatchesFalseOnTimestampOrNonce() {
        let input = DynamicSecretInput(query: "role_id=1", timestamp: "1700000000", nonce: "123456")
        let value = DynamicSecretGenerator.sign(input)
        XCTAssertFalse(
            DynamicSecretGenerator.matches(
                DynamicSecret(timestamp: "1700000001", nonce: "123456", value: value),
                input: input
            )
        )
        XCTAssertFalse(
            DynamicSecretGenerator.matches(
                DynamicSecret(timestamp: "1700000000", nonce: "654321", value: value),
                input: input
            )
        )
    }

    /// 场景：摘要错误。
    /// 期望：`matches` 返回 false。
    func testMatchesFalseOnWrongValue() {
        let input = DynamicSecretInput(query: "role_id=1", timestamp: "1700000000", nonce: "123456")
        XCTAssertFalse(
            DynamicSecretGenerator.matches(
                DynamicSecret(timestamp: "1700000000", nonce: "123456", value: String(repeating: "0", count: 32)),
                input: input
            )
        )
    }

    /// 场景：已知 MD5 向量。
    /// 期望：空串与 `abc` 都命中标准结果，确认实现用的是标准 MD5。
    func testMD5KnownVectors() {
        XCTAssertEqual(DynamicSecretGenerator.md5Hex(""), "d41d8cd98f00b204e9800998ecf8427e")
        XCTAssertEqual(DynamicSecretGenerator.md5Hex("abc"), "900150983cd24fb0d6963f7d28e17f72")
    }
}
