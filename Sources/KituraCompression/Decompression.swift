/**
 * Copyright IBM Corporation 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Kitura
import CZlib
import LoggerAPI

import Foundation


public struct GzipError: Swift.Error {
    
    public enum GzipErrorType {
        case stream
        case data
        case memory
        case buffer
        case version
        case unknown(code: Int)
    }
    
    /// Error kind.
    public let errorType: GzipErrorType
    
    /// Returned message by zlib.
    public let message: String
    
    
    internal init(code: Int32, msg: UnsafePointer<CChar>?) {
        
        self.message = {
            guard let msg = msg, let message = String(validatingUTF8: msg) else {
                return "Unknown gzip error"
            }
            return message
        }()
        
        self.errorType = {
            switch code {
            case Z_STREAM_ERROR:
                return .stream
            case Z_DATA_ERROR:
                return .data
            case Z_MEM_ERROR:
                return .memory
            case Z_BUF_ERROR:
                return .buffer
            case Z_VERSION_ERROR:
                return .version
            default:
                return .unknown(code: Int(code))
            }
        }()
    }
    
    
    public var localizedDescription: String {
        return self.message
    }
    
}


extension Data {
    
    private func createStream() -> z_stream {
        var stream = z_stream()
        self.withUnsafeBytes { (bytes: UnsafePointer<Bytef>) in
            stream.next_in = UnsafeMutablePointer<Bytef>(mutating: bytes)
        }
        stream.avail_in = uint(self.count)
        
        return stream
    }
    
    public func decompress() throws -> Data {
        
        guard !self.isEmpty else {
            return Data()
        }
        
        let contiguousData = self.withUnsafeBytes { Data(bytes: $0, count: self.count) }
        var stream = contiguousData.createStream()
        var status: Int32
        
        status = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, Int32(DataSize.stream))
        
        guard status == Z_OK else {
            throw GzipError(code: status, msg: stream.msg)
        }
        
        var data = Data(capacity: contiguousData.count * 2)
        
        repeat {
            if Int(stream.total_out) >= data.count {
                data.count += contiguousData.count / 2
            }
            
            data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<Bytef>) in
                stream.next_out = bytes.advanced(by: Int(stream.total_out))
            }
            stream.avail_out = uInt(data.count) - uInt(stream.total_out)
            
            status = inflate(&stream, Z_SYNC_FLUSH)
            
        } while status == Z_OK
        
        guard inflateEnd(&stream) == Z_OK && status == Z_STREAM_END else {
            // inflate returns:
            // Z_DATA_ERROR   The input data was corrupted (input stream not conforming to the zlib format or incorrect check value).
            // Z_STREAM_ERROR The stream structure was inconsistent (for example if next_in or next_out was NULL).
            // Z_MEM_ERROR    There was not enough memory.
            // Z_BUF_ERROR    No progress is possible or there was not enough room in the output buffer when Z_FINISH is used.
            
            throw GzipError(code: status, msg: stream.msg)
        }
        
        data.count = Int(stream.total_out)
        
        return data
        
    }
}

private struct DataSize {
    
    static let chunk = 2 ^ 14
    static let stream = MemoryLayout<z_stream>.size
    
    private init() { }
}



