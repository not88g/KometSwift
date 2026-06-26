// Mirrors packet_framer.dart exactly.
// Protocol: 10-byte header + MsgPack payload (optionally LZ4-compressed).
//
// Header layout (big-endian):
//   [0]    ver     UInt8
//   [1-2]  cmd     UInt16
//   [3]    seq     UInt8
//   [4-5]  opcode  UInt16
//   [6-9]  packedLen UInt32  — bit 24 = compression flag; lower 24 bits = payload byte count
//
// If compressed: first 4 bytes of payload = original uncompressed size (UInt32 BE),
//                remaining bytes = LZ4-compressed data.

import Foundation

struct Packet {
    let ver: UInt8
    let cmd: UInt16
    let seq: UInt8
    let opcode: UInt16
    let payload: [String: Any]
}

enum PacketFramerError: Error {
    case tooShort
    case lz4DecompressionFailed
    case msgpackDecodeFailed
}

// Compression threshold — matches Flutter: payloadBytes.length >= 32
private let compressionThreshold = 32

func packPacket(ver: UInt8 = 1, cmd: UInt16, seq: UInt8, opcode: UInt16, payload: [String: Any]) throws -> Data {
    var payloadBytes = try MessagePackCodec.encode(payload)
    var isCompressed = false

    if payloadBytes.count >= compressionThreshold {
        // Prepend 4-byte original size (UInt32 BE), then LZ4-compressed data
        var uncompressedSize = UInt32(payloadBytes.count).bigEndian
        let sizeBytes = Data(bytes: &uncompressedSize, count: 4)
        let compressed = try LZ4Codec.compress(payloadBytes)
        payloadBytes = sizeBytes + compressed
        isCompressed = true
    }

    var packedLen = UInt32(payloadBytes.count)
    if isCompressed { packedLen |= (1 << 24) }

    var header = Data(count: 10)
    header[0] = ver
    header.storeUInt16BE(cmd, at: 1)
    header[3] = seq
    header.storeUInt16BE(opcode, at: 4)
    header.storeUInt32BE(packedLen, at: 6)

    return header + payloadBytes
}

func unpackPacket(_ data: Data) throws -> Packet {
    guard data.count >= 10 else { throw PacketFramerError.tooShort }

    let ver    = data[0]
    let cmd    = data.loadUInt16BE(at: 1)
    let seq    = data[3]
    let opcode = data.loadUInt16BE(at: 4)
    let raw    = data.loadUInt32BE(at: 6)

    let isCompressed = (raw >> 24) != 0
    let payloadLength = Int(raw & 0x00FFFFFF)

    guard data.count >= 10 + payloadLength else { throw PacketFramerError.tooShort }

    var payloadBytes = data.subdata(in: 10..<(10 + payloadLength))

    if isCompressed {
        guard payloadBytes.count >= 4 else { throw PacketFramerError.lz4DecompressionFailed }
        let expectedSize = Int(payloadBytes.loadUInt32BE(at: 0))
        let compressed = payloadBytes.subdata(in: 4..<payloadBytes.count)
        payloadBytes = try LZ4Codec.decompress(compressed, expectedSize: expectedSize)
    }

    let decoded = try MessagePackCodec.decode(payloadBytes)
    return Packet(ver: ver, cmd: cmd, seq: seq, opcode: opcode, payload: decoded)
}

// MARK: - Data helpers

private extension Data {
    func loadUInt16BE(at offset: Int) -> UInt16 {
        let hi = UInt16(self[offset])
        let lo = UInt16(self[offset + 1])
        return (hi << 8) | lo
    }

    func loadUInt32BE(at offset: Int) -> UInt32 {
        let b0 = UInt32(self[offset])
        let b1 = UInt32(self[offset + 1])
        let b2 = UInt32(self[offset + 2])
        let b3 = UInt32(self[offset + 3])
        return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    }

    mutating func storeUInt16BE(_ value: UInt16, at offset: Int) {
        self[offset]     = UInt8(value >> 8)
        self[offset + 1] = UInt8(value & 0xFF)
    }

    mutating func storeUInt32BE(_ value: UInt32, at offset: Int) {
        self[offset]     = UInt8((value >> 24) & 0xFF)
        self[offset + 1] = UInt8((value >> 16) & 0xFF)
        self[offset + 2] = UInt8((value >>  8) & 0xFF)
        self[offset + 3] = UInt8( value        & 0xFF)
    }
}
