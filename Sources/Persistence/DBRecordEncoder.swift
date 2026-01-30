import GRDB

private struct NilIgnoringEncoder: Encoder {
    var grdbEncoder: any Encoder

    var codingPath: [any CodingKey] {
        grdbEncoder.codingPath
    }

    var userInfo: [CodingUserInfoKey : Any] {
        grdbEncoder.userInfo
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(
            NilIgnoringKeyedContainer(wrapped: grdbEncoder.container(keyedBy: type))
        )
    }

    func unkeyedContainer() -> any UnkeyedEncodingContainer {
        grdbEncoder.unkeyedContainer()
    }

    func singleValueContainer() -> any SingleValueEncodingContainer {
        grdbEncoder.singleValueContainer()
    }
}

private struct NilIgnoringKeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    var wrapped: KeyedEncodingContainer<Key>

    var codingPath: [any CodingKey] {
        wrapped.codingPath
    }

    mutating func superEncoder() -> any Encoder {
        NilIgnoringEncoder(grdbEncoder: wrapped.superEncoder())
    }

    mutating func encode(_ value: Bool, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode(_ value: Int, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode(_ value: Int8, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode(_ value: Int16, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode(_ value: Int32, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode(_ value: Int64, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode(_ value: UInt, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode(_ value: Float, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode(_ value: Double, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode(_ value: String, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encode<T : Encodable>(_ value: T, forKey key: Key) throws {
        try wrapped.encode(value, forKey: key)
    }

    mutating func encodeNil(forKey key: Key) throws {
        try wrapped.encodeNil(forKey: key)
    }

    mutating func encodeIfPresent(_ value: Bool?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Float?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Double?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: String?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func encodeIfPresent<T: Encodable>(_ value: T?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        }
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key,
    ) -> KeyedEncodingContainer<NestedKey> {
        wrapped.nestedContainer(keyedBy: keyType, forKey: key)
    }

    mutating func nestedUnkeyedContainer(
        forKey key: Key,
    ) -> any UnkeyedEncodingContainer {
        wrapped.nestedUnkeyedContainer(forKey: key)
    }

    mutating func superEncoder(forKey key: Key) -> any Encoder {
        NilIgnoringEncoder(grdbEncoder: wrapped.superEncoder(forKey: key))
    }
}

private struct Adapter<T: Encodable>: Encodable, EncodableRecord {
    var value: T

    func encode(to encoder: any Encoder) throws {
        try value.encode(to: NilIgnoringEncoder(grdbEncoder: encoder))
    }
}

func encodeNonNilFields<T: Encodable>(
    of value: T,
    into container: inout PersistenceContainer,
) throws {
    try Adapter(value: value).encode(to: &container)
}
