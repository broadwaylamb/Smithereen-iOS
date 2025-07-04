// Copied from Vapor and stripped of unneeded parts
// https://github.com/vapor/vapor/blob/0386747657bd5714979b7158674f7e8a6dbe952c/Sources/Vapor/URLEncodedForm/URLEncodedFormEncoder.swift

import Foundation

/// Encodes `Encodable` instances to `application/x-www-form-urlencoded` data.
///
///     print(user) /// User
///     let data = try URLEncodedFormEncoder().encode(user)
///     print(data) /// Data
///
/// URL-encoded forms are commonly used by websites to send form data via POST requests. This encoding is relatively
/// efficient for small amounts of data but must be percent-encoded.  `multipart/form-data` is more efficient for sending
/// large data blobs like files.
///
/// See [Mozilla's](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST) docs for more information about
/// url-encoded forms.
/// NOTE: This implementation of the encoder does not support encoding booleans to "flags".
public struct URLEncodedFormEncoder: Sendable {
    /// Used to capture URLForm Coding Configuration used for encoding.
    public struct Configuration: Sendable {
        /// Supported array encodings.
        public enum ArrayEncoding: Sendable {
            /// Arrays are serialized as separate values with bracket suffixed keys.
            /// For example, `foo = [1,2,3]` would be serialized as `foo[]=1&foo[]=2&foo[]=3`.
            case bracket
            /// Arrays are serialized as a single value with character-separated items.
            /// For example, `foo = [1,2,3]` would be serialized as `foo=1,2,3`.
            case separator(Character)
            /// Arrays are serialized as separate values.
            /// For example, `foo = [1,2,3]` would be serialized as `foo=1&foo=2&foo=3`.
            case values
        }

        /// Supported date formats
        public enum DateEncodingStrategy: Sendable {
            /// Seconds since 1 January 1970 00:00:00 UTC (Unix Timestamp)
            case secondsSince1970
            /// ISO 8601 formatted date
            case iso8601
            /// Using custom callback
            case custom(@Sendable (Date, Encoder) throws -> Void)
        }
        /// Specified array encoding.
        public var arrayEncoding: ArrayEncoding
        public var dateEncodingStrategy: DateEncodingStrategy
        public var userInfo: [CodingUserInfoKey: Sendable]

        /// Creates a new `Configuration`.
        ///
        ///  - parameters:
        ///     - arrayEncoding: Specified array encoding. Defaults to `.bracket`.
        ///     - dateFormat: Format to encode date format too. Defaults to `secondsSince1970`
        public init(
            arrayEncoding: ArrayEncoding = .bracket,
            dateEncodingStrategy: DateEncodingStrategy = .secondsSince1970,
            userInfo: [CodingUserInfoKey: Sendable] = [:]
        ) {
            self.arrayEncoding = arrayEncoding
            self.dateEncodingStrategy = dateEncodingStrategy
            self.userInfo = userInfo
        }
    }

    private let configuration: Configuration

    /// Create a new `URLEncodedFormEncoder`.
    ///
    /// - Parameters:
    ///  - configuration: Defines how encoding is done; see ``URLEncodedFormEncoder/Configuration`` for more information
    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    /// Encodes the supplied ``Encodable`` object to ``String``.
    ///
    ///     print(user) // User
    ///     let data = try URLEncodedFormEncoder().encode(user)
    ///     print(data) // "name=Vapor&age=3"
    ///
    /// - Parameters:
    ///   - encodable: Generic ``Encodable`` object (``E``) to encode.
    ///   - userInfo: Overrides the default coder user info.
    /// - Returns: Encoded ``String``
    /// - Throws: Any error that may occur while attempting to encode the specified type.
    public func encode<E: Encodable>(
        _ encodable: E,
        userInfo: [CodingUserInfoKey: Sendable] = [:]
    ) throws -> String {
        try encode(encodable, userInfo: userInfo) {
            try URLEncodedFormSerializer().serialize($0)
        }
    }

    public func encode<E: Encodable>(
        _ encodable: E,
        into queryItems: inout [URLQueryItem],
        userInfo: [CodingUserInfoKey: Sendable] = [:]
    ) throws {
        try encode(encodable, userInfo: userInfo) {
            try URLEncodedFormSerializer().serialize($0, into: &queryItems)
        }
    }

    private func encode<E: Encodable, Output>(
        _ encodable: E,
        userInfo: [CodingUserInfoKey: Sendable],
        serialize: (URLEncodedFormData) throws -> Output,
    ) throws -> Output {
        var configuration = self.configuration
        if !userInfo.isEmpty {
            configuration.userInfo.merge(userInfo) { $1 }
        }
        let encoder = _Encoder(codingPath: [], configuration: configuration)
        try encodable.encode(to: encoder)
        return try serialize(encoder.getData())
    }
}

// MARK: Private

private protocol _Container {
    func getData() throws -> URLEncodedFormData
}

private class _Encoder: Encoder, _Container {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any] { self.configuration.userInfo }

    private var container: _Container? = nil
    private let configuration: URLEncodedFormEncoder.Configuration

    func getData() throws -> URLEncodedFormData { try self.container?.getData() ?? [] }

    init(codingPath: [CodingKey], configuration: URLEncodedFormEncoder.Configuration) {
        self.codingPath = codingPath
        self.configuration = configuration
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = KeyedContainer<Key>(codingPath: codingPath, configuration: configuration)
        self.container = container
        return .init(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container = UnkeyedContainer(codingPath: codingPath, configuration: configuration)
        self.container = container
        return container
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        let container = SingleValueContainer(codingPath: codingPath, configuration: configuration)
        self.container = container
        return container
    }

    private final class KeyedContainer<Key>: KeyedEncodingContainerProtocol, _Container
        where Key: CodingKey
    {
        var codingPath: [CodingKey]
        var internalData: URLEncodedFormData = []
        var childContainers: [String: _Container] = [:]

        func getData() throws -> URLEncodedFormData {
            var result = self.internalData
            for (key, childContainer) in self.childContainers {
                result.children[key] = try childContainer.getData()
            }
            return result
        }

        private let configuration: URLEncodedFormEncoder.Configuration

        init(
            codingPath: [CodingKey],
            configuration: URLEncodedFormEncoder.Configuration
        ) {
            self.codingPath = codingPath
            self.configuration = configuration
        }

        /// See `KeyedEncodingContainerProtocol`
        func encodeNil(forKey key: Key) throws {
            // skip
        }

        /// See `KeyedEncodingContainerProtocol`
        func encode<T>(_ value: T, forKey key: Key) throws
            where T : Encodable
        {
            if let date = value as? Date {
                self.internalData.children[key.stringValue] = try self.configuration.encodeDate(date, codingPath: self.codingPath, forKey: key)
            } else if let convertible = value as? URLQueryFragmentConvertible {
                self.internalData.children[key.stringValue] = URLEncodedFormData(values: [convertible.urlQueryFragmentValue])
            } else {
                let encoder = _Encoder(codingPath: self.codingPath + [key], configuration: self.configuration)
                try value.encode(to: encoder)
                self.internalData.children[key.stringValue] = try encoder.getData()
            }
        }

        /// See `KeyedEncodingContainerProtocol`
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey>
            where NestedKey: CodingKey
        {
            let container = KeyedContainer<NestedKey>(
                codingPath: self.codingPath + [key],
                configuration: self.configuration
            )
            self.childContainers[key.stringValue] = container
            return .init(container)
        }

        /// See `KeyedEncodingContainerProtocol`
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            let container = UnkeyedContainer(
                codingPath: self.codingPath + [key],
                configuration: self.configuration
            )
            self.childContainers[key.stringValue] = container
            return container
        }

        /// See `KeyedEncodingContainerProtocol`
        func superEncoder() -> Encoder {
            let encoder = _Encoder(codingPath: self.codingPath + [BasicCodingKey.key("super")], configuration: self.configuration)
            self.childContainers["super"] = encoder
            return encoder
        }

        /// See `KeyedEncodingContainerProtocol`
        func superEncoder(forKey key: Key) -> Encoder {
            let encoder = _Encoder(codingPath: self.codingPath + [key], configuration: self.configuration)
            self.childContainers[key.stringValue] = encoder
            return encoder
        }
    }

    /// Private `UnkeyedEncodingContainer`.
    private final class UnkeyedContainer: UnkeyedEncodingContainer, _Container {
        var codingPath: [CodingKey]
        var count: Int = 0
        var internalData: URLEncodedFormData = []
        var childContainers: [Int: _Container] = [:]
        private let configuration: URLEncodedFormEncoder.Configuration

        func getData() throws -> URLEncodedFormData {
            var result = self.internalData
            for (key, childContainer) in self.childContainers {
                result.children[String(key)] = try childContainer.getData()
            }
            switch self.configuration.arrayEncoding {
            case .separator(let arraySeparator):
                var valuesToImplode = result.values
                result.values = []
                if case .bracket = self.configuration.arrayEncoding, let emptyStringChild = self.internalData.children[""] {
                    valuesToImplode = valuesToImplode + emptyStringChild.values
                    result.children[""]?.values = []
                }
                let implodedValue = valuesToImplode.joined(separator: String(arraySeparator))
                result.values = [implodedValue]
            case .bracket, .values:
                break
            }
            return result
        }

        init(codingPath: [CodingKey], configuration: URLEncodedFormEncoder.Configuration) {
            self.codingPath = codingPath
            self.configuration = configuration
        }

        func encodeNil() throws {
            // skip
        }

        func encode<T>(_ value: T) throws where T: Encodable {
            if let date = value as? Date {
                let encodedDate = try self.configuration.encodeDate(date, codingPath: self.codingPath, forKey: BasicCodingKey.index(self.count))
                switch self.configuration.arrayEncoding {
                case .bracket:
                    var emptyStringChild = self.internalData.children[""] ?? []
                    emptyStringChild.values.append(contentsOf: encodedDate.values)
                    self.internalData.children[""] = emptyStringChild
                case .separator, .values:
                    self.internalData.values.append(contentsOf: encodedDate.values)
                }
            } else if let convertible = value as? URLQueryFragmentConvertible {
                let value = convertible.urlQueryFragmentValue
                switch self.configuration.arrayEncoding {
                case .bracket:
                    var emptyStringChild = self.internalData.children[""] ?? []
                    emptyStringChild.values.append(value)
                    self.internalData.children[""] = emptyStringChild
                case .separator, .values:
                    self.internalData.values.append(value)
                }
            } else {
                let encoder = _Encoder(codingPath: self.codingPath + [BasicCodingKey.index(self.count)], configuration: configuration)
                try value.encode(to: encoder)
                let childData = try encoder.getData()
                if childData.hasOnlyValues {
                    switch self.configuration.arrayEncoding {
                    case .bracket:
                        var emptyStringChild = self.internalData.children[""] ?? []
                        emptyStringChild.values.append(contentsOf: childData.values)
                        self.internalData.children[""] = emptyStringChild
                    case .separator, .values:
                        self.internalData.values.append(contentsOf: childData.values)
                    }
                } else {
                    self.internalData.children[self.count.description] = try encoder.getData()
                }
            }
            self.count += 1 // we don't want to do this if anything earlier threw an error
        }

        /// See UnkeyedEncodingContainer.nestedContainer
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey>
            where NestedKey: CodingKey
        {
            defer { self.count += 1 }
            let container = KeyedContainer<NestedKey>(
                codingPath: self.codingPath + [BasicCodingKey.index(self.count)],
                configuration: self.configuration
            )
            self.childContainers[self.count] = container
            return .init(container)
        }

        /// See UnkeyedEncodingContainer.nestedUnkeyedContainer
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            defer { self.count += 1 }
            let container = UnkeyedContainer(
                codingPath: self.codingPath + [BasicCodingKey.index(self.count)],
                configuration: self.configuration
            )
            self.childContainers[self.count] = container
            return container
        }

        /// See UnkeyedEncodingContainer.superEncoder
        func superEncoder() -> Encoder {
            defer { self.count += 1 }
            let encoder = _Encoder(codingPath: self.codingPath + [BasicCodingKey.index(self.count)], configuration: self.configuration)
            self.childContainers[self.count] = encoder
            return encoder
        }
    }

    /// Private `SingleValueEncodingContainer`.
    private final class SingleValueContainer: SingleValueEncodingContainer, _Container {
        /// See `SingleValueEncodingContainer`
        var codingPath: [CodingKey]

        func getData() throws -> URLEncodedFormData { self.data }

        /// The data being encoded
        var data: URLEncodedFormData = []

        private let configuration: URLEncodedFormEncoder.Configuration

        /// Creates a new single value encoder
        init(
            codingPath: [CodingKey],
            configuration: URLEncodedFormEncoder.Configuration
        ) {
            self.codingPath = codingPath
            self.configuration = configuration
        }

        /// See `SingleValueEncodingContainer`
        func encodeNil() throws {
            // skip
        }

        /// See `SingleValueEncodingContainer`
        func encode<T>(_ value: T) throws where T: Encodable {
            if let date = value as? Date {
                self.data = try self.configuration.encodeDate(date, codingPath: self.codingPath, forKey: nil)
            } else if let convertible = value as? URLQueryFragmentConvertible {
                self.data.values.append(convertible.urlQueryFragmentValue)
            } else {
                let encoder = _Encoder(codingPath: self.codingPath, configuration: self.configuration)
                try value.encode(to: encoder)
                self.data = try encoder.getData()
            }
        }
    }
}

private extension URLEncodedFormEncoder.Configuration {
    func encodeDate(_ date: Date, codingPath: [CodingKey], forKey key: CodingKey?) throws -> URLEncodedFormData {
        switch dateEncodingStrategy {
        case .secondsSince1970:
            return URLEncodedFormData(values: [date.urlQueryFragmentValue])
        case .iso8601:
            return URLEncodedFormData(values: [
                ISO8601DateFormatter().string(from: date).urlQueryFragmentValue
            ])
        case .custom(let callback):
            let newCodingPath = codingPath + (key.map { [$0] } ?? [])
            let encoder = _Encoder(codingPath: newCodingPath, configuration: self)
            try callback(date, encoder)
            return try encoder.getData()
        }
    }
}

private extension EncodingError {
    static func invalidValue(_ value: Any, at path: [CodingKey]) -> EncodingError {
        let pathString = path.map { $0.stringValue }.joined(separator: ".")
        let context = EncodingError.Context(
            codingPath: path,
            debugDescription: "Invalid value at '\(pathString)': \(value)"
        )
        return Swift.EncodingError.invalidValue(value, context)
    }
}

/// Represents application/x-www-form-urlencoded encoded data.
private struct URLEncodedFormData: ExpressibleByArrayLiteral, ExpressibleByStringLiteral, ExpressibleByDictionaryLiteral, Equatable {
    var values: [URLQueryFragment]
    var children: [String: URLEncodedFormData]
    let maxRecursionDepth = 100

    var hasOnlyValues: Bool {
        return children.count == 0
    }

    var allChildKeysAreSequentialIntegers: Bool {
        for i in 0...children.count-1 {
            if !children.keys.contains(String(i)) {
                return false
            }
        }
        return true
    }

    init(values: [URLQueryFragment] = [], children: [String: URLEncodedFormData] = [:]) {
        self.values = values
        self.children = children
    }

    init(stringLiteral: String) {
        self.values = [stringLiteral]
        self.children = [:]
    }

    init(arrayLiteral: String...) {
        self.values = arrayLiteral
        self.children = [:]
    }

    init(dictionaryLiteral: (String, URLEncodedFormData)...) {
        self.values = []
        self.children = Dictionary(uniqueKeysWithValues: dictionaryLiteral)
    }

    mutating func set(value: URLQueryFragment, forPath path: [String], recursionDepth: Int) throws {
        guard recursionDepth <= maxRecursionDepth else {
            throw URLEncodedFormError.reachedNestingLimit
        }
        guard let firstElement = path.first else {
            self.values.append(value)
            return
        }
        var child: URLEncodedFormData
        if let existingChild = self.children[firstElement] {
            child = existingChild
        } else {
            child = []
        }
        try child.set(value: value, forPath: Array(path[1...]), recursionDepth: recursionDepth + 1)
        self.children[firstElement] = child
    }
}

private struct URLEncodedFormSerializer: Sendable {
    func serialize(_ data: URLEncodedFormData, codingPath: [CodingKey] = []) throws -> String {
        var entries: [String] = []
        let key = try codingPath.toURLEncodedKey()
        for value in data.values {
            if codingPath.count == 0 {
                entries.append(value)
            } else {
                entries.append(key + "=" + value)
            }
        }
        for (key, child) in data.children {
            try entries.append(serialize(child, codingPath: codingPath + [_CodingKey(stringValue: key) as CodingKey]))
        }
        return entries.joined(separator: "&")
    }

    func serialize(
        _ data: URLEncodedFormData,
        into queryItems: inout [URLQueryItem],
        codingPath: [CodingKey] = []
    ) throws {
        let key = try codingPath.toURLEncodedKey()
        for value in data.values {
            if codingPath.count == 0 {
                queryItems.append(URLQueryItem(name: value, value: nil))
            } else {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }
        for (key, child) in data.children {
            try serialize(
                child,
                into: &queryItems,
                codingPath: codingPath + [_CodingKey(stringValue: key) as CodingKey]
            )
        }
    }

    struct _CodingKey: CodingKey {
        var stringValue: String

        init(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int?

        init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = intValue.description
        }
    }
}

extension Array where Element == CodingKey {
    func toURLEncodedKey() throws -> String {
        if count < 1 {
            return ""
        }
        return try self[0].stringValue.urlEncoded(codingPath: self) + self[1...].map { (key: CodingKey) -> String in
            try "[" + key.stringValue.urlEncoded(codingPath: self) + "]"
        }.joined()
    }
}

/// Errors thrown while encoding/decoding `application/x-www-form-urlencoded` data.
private enum URLEncodedFormError: Error {
    case malformedKey(key: Substring)
    case reachedNestingLimit
}

// MARK: Utilities

/// A basic `CodingKey` implementation.
private enum BasicCodingKey: CodingKey, Hashable {
    case key(String)
    case index(Int)

    /// See `CodingKey`.
    var stringValue: String {
        switch self {
        case .index(let index): return index.description
        case .key(let key): return key
        }
    }

    /// See `CodingKey`.
    var intValue: Int? {
        switch self {
        case .index(let index): return index
        case .key(let key): return Int(key)
        }
    }

    /// See `CodingKey`.
    init?(stringValue: String) {
        self = .key(stringValue)
    }

    /// See `CodingKey`.
    init?(intValue: Int) {
        self = .index(intValue)
    }

    init(_ codingKey: CodingKey) {
        if let intValue = codingKey.intValue {
            self = .index(intValue)
        } else {
            self = .key(codingKey.stringValue)
        }
    }
}

extension String {
    /// Prepares a `String` for inclusion in form-urlencoded data.
    func urlEncoded(codingPath: [CodingKey] = []) throws -> String {
        guard let result = self.addingPercentEncoding(
            withAllowedCharacters: Characters.allowedCharacters
        ) else {
            throw EncodingError.invalidValue(self, EncodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unable to add percent encoding to \(self)"
            ))
        }
        return result
    }
}

/// Characters allowed in form-urlencoded data.
private enum Characters {
    // https://url.spec.whatwg.org/#application-x-www-form-urlencoded-percent-encode-set
    static let allowedCharacters: CharacterSet = {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "*-._")
        return allowed
    }()
}

private typealias URLQueryFragment = String

/// Capable of converting to / from `URLQueryFragment`.
private protocol URLQueryFragmentConvertible {
    /// Converts self to `URLQueryFragment`.
    var urlQueryFragmentValue: URLQueryFragment { get }
}

extension String: URLQueryFragmentConvertible {
    fileprivate var urlQueryFragmentValue: URLQueryFragment {
        return self
    }
}

extension FixedWidthInteger {
    /// `URLEncodedFormDataConvertible` conformance.
    fileprivate var urlQueryFragmentValue: URLQueryFragment {
        return description
    }
}

extension Int: URLQueryFragmentConvertible {}
extension Int8: URLQueryFragmentConvertible {}
extension Int16: URLQueryFragmentConvertible {}
extension Int32: URLQueryFragmentConvertible {}
extension Int64: URLQueryFragmentConvertible {}
extension UInt: URLQueryFragmentConvertible {}
extension UInt8: URLQueryFragmentConvertible {}
extension UInt16: URLQueryFragmentConvertible {}
extension UInt32: URLQueryFragmentConvertible {}
extension UInt64: URLQueryFragmentConvertible {}


extension BinaryFloatingPoint {
    fileprivate var urlQueryFragmentValue: URLQueryFragment {
        return Double(self).description
    }
}

extension Float: URLQueryFragmentConvertible { }
extension Double: URLQueryFragmentConvertible { }

extension Bool: URLQueryFragmentConvertible {
    fileprivate var urlQueryFragmentValue: URLQueryFragment {
        return description
    }
}

extension Decimal: URLQueryFragmentConvertible {
    fileprivate var urlQueryFragmentValue: URLQueryFragment {
        return description
    }
}

extension Date: URLQueryFragmentConvertible {
    fileprivate var urlQueryFragmentValue: URLQueryFragment {
        return timeIntervalSince1970.urlQueryFragmentValue
    }
}

extension URL: URLQueryFragmentConvertible {
    fileprivate var urlQueryFragmentValue: URLQueryFragment {
        self.absoluteString.urlQueryFragmentValue
    }
}
