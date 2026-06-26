// Uses system libcompression — no third-party dependency needed on iOS.
// Mirrors es_compression/lz4 behaviour from the Flutter app.

import Foundation
import Compression

enum LZ4Codec {
    enum Error: Swift.Error { case compressionFailed, decompressionFailed }

    static func compress(_ data: Data) throws -> Data {
        let srcSize = data.count
        // Maximum LZ4 output bound ≈ srcSize + srcSize/255 + 16
        let dstBound = srcSize + srcSize / 255 + 16
        var dst = [UInt8](repeating: 0, count: dstBound)
        let written = data.withUnsafeBytes { src in
            compression_encode_buffer(
                &dst, dstBound,
                src.baseAddress!.assumingMemoryBound(to: UInt8.self),
                srcSize,
                nil, COMPRESSION_LZ4_RAW
            )
        }
        guard written > 0 else { throw Error.compressionFailed }
        return Data(dst.prefix(written))
    }

    static func decompress(_ data: Data, expectedSize: Int) throws -> Data {
        guard expectedSize > 0 else { return Data() }
        var dst = [UInt8](repeating: 0, count: expectedSize)
        let written = data.withUnsafeBytes { src in
            compression_decode_buffer(
                &dst, expectedSize,
                src.baseAddress!.assumingMemoryBound(to: UInt8.self),
                data.count,
                nil, COMPRESSION_LZ4_RAW
            )
        }
        guard written > 0 else { throw Error.decompressionFailed }
        return Data(dst.prefix(written))
    }
}
