// Minimal MsgPack encoder/decoder matching msgpack_dart's output.
// Supports: nil, bool, int (up to int64), float/double, string (utf8), binary,
//           array, map. Ext types are surfaced as raw Data.

import Foundation

enum MessagePackCodec {
    enum CodecError: Error { case encodeFailed(String), decodeFailed(String), insufficientData }

    // MARK: - Encode

    static func encode(_ value: Any) throws -> Data {
        var out = Data()
        try appendValue(value, to: &out)
        return out
    }

    private static func appendValue(_ value: Any, to out: inout Data) throws {
        switch value {
        case is NSNull, is Optional<Any> where (value as? Optional<Any>) == nil:
            out.append(0xc0)

        case let v as Bool:
            out.append(v ? 0xc3 : 0xc2)

        case let v as Int:
            try appendInt(v, to: &out)

        case let v as Int64:
            try appendInt(Int(v), to: &out)

        case let v as UInt64:
            out.append(contentsOf: [0xcf] + bigEndianBytes(UInt64(v)))

        case let v as Double:
            var bits = v.bitPattern
            out.append(0xcb)
            out.append(contentsOf: bigEndianBytes(bits))

        case let v as Float:
            var bits = v.bitPattern
            out.append(0xca)
            out.append(contentsOf: bigEndianBytes(UInt32(bits)))

        case let v as String:
            let utf8 = Array(v.utf8)
            let len = utf8.count
            if len <= 31 {
                out.append(UInt8(0xa0 | len))
            } else if len <= 0xFF {
                out.append(contentsOf: [0xd9, UInt8(len)])
            } else if len <= 0xFFFF {
                out.append(0xda)
                out.append(contentsOf: bigEndianBytes(UInt16(len)))
            } else {
                out.append(0xdb)
                out.append(contentsOf: bigEndianBytes(UInt32(len)))
            }
            out.append(contentsOf: utf8)

        case let v as Data:
            let len = v.count
            if len <= 0xFF {
                out.append(contentsOf: [0xc4, UInt8(len)])
            } else if len <= 0xFFFF {
                out.append(0xc5)
                out.append(contentsOf: bigEndianBytes(UInt16(len)))
            } else {
                out.append(0xc6)
                out.append(contentsOf: bigEndianBytes(UInt32(len)))
            }
            out.append(v)

        case let arr as [Any]:
            let len = arr.count
            if len <= 15 {
                out.append(UInt8(0x90 | len))
            } else if len <= 0xFFFF {
                out.append(0xdc)
                out.append(contentsOf: bigEndianBytes(UInt16(len)))
            } else {
                out.append(0xdd)
                out.append(contentsOf: bigEndianBytes(UInt32(len)))
            }
            for item in arr { try appendValue(item, to: &out) }

        case let dict as [String: Any]:
            let len = dict.count
            if len <= 15 {
                out.append(UInt8(0x80 | len))
            } else if len <= 0xFFFF {
                out.append(0xde)
                out.append(contentsOf: bigEndianBytes(UInt16(len)))
            } else {
                out.append(0xdf)
                out.append(contentsOf: bigEndianBytes(UInt32(len)))
            }
            for (k, v) in dict {
                try appendValue(k, to: &out)
                try appendValue(v, to: &out)
            }

        default:
            throw CodecError.encodeFailed("Unsupported type: \(type(of: value))")
        }
    }

    private static func appendInt(_ v: Int, to out: inout Data) throws {
        switch v {
        case 0...127:           out.append(UInt8(v))
        case -32 ..< 0:         out.append(UInt8(bitPattern: Int8(v)))
        case 128...0xFF:        out.append(contentsOf: [0xcc, UInt8(v)])
        case 0x100...0xFFFF:    out.append(0xcd); out.append(contentsOf: bigEndianBytes(UInt16(v)))
        case 0x10000...0xFFFFFFFF: out.append(0xce); out.append(contentsOf: bigEndianBytes(UInt32(v)))
        case Int.min ..< -32:
            if v >= -128   { out.append(contentsOf: [0xd0, UInt8(bitPattern: Int8(v))]) }
            else if v >= -32768 { out.append(0xd1); out.append(contentsOf: bigEndianBytes(UInt16(bitPattern: Int16(v)))) }
            else if v >= -2147483648 { out.append(0xd2); out.append(contentsOf: bigEndianBytes(UInt32(bitPattern: Int32(v)))) }
            else { out.append(0xd3); out.append(contentsOf: bigEndianBytes(UInt64(bitPattern: Int64(v)))) }
        default:
            out.append(0xd3); out.append(contentsOf: bigEndianBytes(UInt64(bitPattern: Int64(v))))
        }
    }

    // MARK: - Decode

    static func decode(_ data: Data) throws -> [String: Any] {
        var offset = 0
        let value = try readValue(from: data, offset: &offset)
        guard let dict = value as? [String: Any] else { throw CodecError.decodeFailed("Root is not a map") }
        return dict
    }

    static func decodeAny(_ data: Data) throws -> Any {
        var offset = 0
        return try readValue(from: data, offset: &offset)
    }

    private static func readValue(from data: Data, offset: inout Int) throws -> Any {
        guard offset < data.count else { throw CodecError.insufficientData }
        let byte = data[offset]; offset += 1

        switch byte {
        case 0xc0: return NSNull()
        case 0xc2: return false
        case 0xc3: return true
        case 0xc4: // bin8
            let len = Int(data[offset]); offset += 1
            return try readBytes(data, offset: &offset, count: len)
        case 0xc5: // bin16
            let len = Int(readUInt16(data, offset: &offset))
            return try readBytes(data, offset: &offset, count: len)
        case 0xc6: // bin32
            let len = Int(readUInt32(data, offset: &offset))
            return try readBytes(data, offset: &offset, count: len)
        case 0xca: // float32
            let raw = readUInt32(data, offset: &offset)
            return Float(bitPattern: raw)
        case 0xcb: // float64
            let raw = readUInt64(data, offset: &offset)
            return Double(bitPattern: raw)
        case 0xcc: let v = data[offset]; offset += 1; return Int(v)
        case 0xcd: return Int(readUInt16(data, offset: &offset))
        case 0xce: return Int(readUInt32(data, offset: &offset))
        case 0xcf: return Int(bitPattern: UInt(readUInt64(data, offset: &offset)))
        case 0xd0: let v = data[offset]; offset += 1; return Int(Int8(bitPattern: v))
        case 0xd1: return Int(Int16(bitPattern: readUInt16(data, offset: &offset)))
        case 0xd2: return Int(Int32(bitPattern: readUInt32(data, offset: &offset)))
        case 0xd3: return Int(Int64(bitPattern: readUInt64(data, offset: &offset)))
        case 0xd9: // str8
            let len = Int(data[offset]); offset += 1
            return try readString(data, offset: &offset, count: len)
        case 0xda: // str16
            let len = Int(readUInt16(data, offset: &offset))
            return try readString(data, offset: &offset, count: len)
        case 0xdb: // str32
            let len = Int(readUInt32(data, offset: &offset))
            return try readString(data, offset: &offset, count: len)
        case 0xdc: // array16
            let len = Int(readUInt16(data, offset: &offset))
            return try readArray(data, offset: &offset, count: len)
        case 0xdd: // array32
            let len = Int(readUInt32(data, offset: &offset))
            return try readArray(data, offset: &offset, count: len)
        case 0xde: // map16
            let len = Int(readUInt16(data, offset: &offset))
            return try readMap(data, offset: &offset, count: len)
        case 0xdf: // map32
            let len = Int(readUInt32(data, offset: &offset))
            return try readMap(data, offset: &offset, count: len)
        default:
            if byte & 0x80 == 0 { return Int(byte) }                        // positive fixint
            if byte & 0xE0 == 0xE0 { return Int(Int8(bitPattern: byte)) }   // negative fixint
            if byte & 0xE0 == 0xA0 { // fixstr
                let len = Int(byte & 0x1F)
                return try readString(data, offset: &offset, count: len)
            }
            if byte & 0xF0 == 0x90 { // fixarray
                let len = Int(byte & 0x0F)
                return try readArray(data, offset: &offset, count: len)
            }
            if byte & 0xF0 == 0x80 { // fixmap
                let len = Int(byte & 0x0F)
                return try readMap(data, offset: &offset, count: len)
            }
            throw CodecError.decodeFailed("Unknown byte: 0x\(String(byte, radix: 16))")
        }
    }

    // MARK: - Helpers

    private static func readBytes(_ d: Data, offset: inout Int, count: Int) throws -> Data {
        guard offset + count <= d.count else { throw CodecError.insufficientData }
        let slice = d.subdata(in: offset..<offset + count); offset += count
        return slice
    }

    private static func readString(_ d: Data, offset: inout Int, count: Int) throws -> String {
        let bytes = try readBytes(d, offset: &offset, count: count)
        return String(bytes: bytes, encoding: .utf8) ?? ""
    }

    private static func readArray(_ d: Data, offset: inout Int, count: Int) throws -> [Any] {
        var arr = [Any]()
        for _ in 0..<count { arr.append(try readValue(from: d, offset: &offset)) }
        return arr
    }

    private static func readMap(_ d: Data, offset: inout Int, count: Int) throws -> [String: Any] {
        var dict = [String: Any]()
        for _ in 0..<count {
            let key = try readValue(from: d, offset: &offset)
            let val = try readValue(from: d, offset: &offset)
            dict["\(key)"] = val
        }
        return dict
    }

    private static func readUInt16(_ d: Data, offset: inout Int) -> UInt16 {
        let v = (UInt16(d[offset]) << 8) | UInt16(d[offset+1]); offset += 2; return v
    }
    private static func readUInt32(_ d: Data, offset: inout Int) -> UInt32 {
        let v = (UInt32(d[offset]) << 24)|(UInt32(d[offset+1]) << 16)|(UInt32(d[offset+2]) << 8)|UInt32(d[offset+3])
        offset += 4; return v
    }
    private static func readUInt64(_ d: Data, offset: inout Int) -> UInt64 {
        var v: UInt64 = 0
        for i in 0..<8 { v = (v << 8) | UInt64(d[offset+i]) }
        offset += 8; return v
    }
}

// MARK: - Big-endian byte helpers

private func bigEndianBytes<T: FixedWidthInteger>(_ value: T) -> [UInt8] {
    var v = value.bigEndian
    return withUnsafeBytes(of: &v) { Array($0) }
}
