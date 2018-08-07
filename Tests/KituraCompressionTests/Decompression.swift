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

enum UnzipError: Error {
    case unzipError()
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

        let contiguousData = self.withUnsafeBytes { Data(bytes: $0, count: self.count) }
        var stream = contiguousData.createStream()
        var status = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, Int32(DataSize.stream))
        
        guard status == Z_OK else {
            throw UnzipError.unzipError()
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
            throw UnzipError.unzipError()
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
