/**
 * Copyright IBM Corporation 2016
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

public class Compression : RouterMiddleware {
    
    public var threshold : Int
    
    public var chunkSize : Int
    
    public var compressionLevel : CompressionLevel
    
    public var compressionStrategy : CompressionStrategy
    
    public var memoryLevel : Int32
    
    public init (threshold: Int = 1024, chunkSize: Int = 65536, compressionLevel: CompressionLevel = CompressionLevel.defaultCompression, compressionStrategy: CompressionStrategy = CompressionStrategy.defaultStrategy, memoryLevel: Int32 = 8) {
        self.threshold = threshold
        self.chunkSize = chunkSize
        self.compressionLevel = compressionLevel
        self.compressionStrategy = compressionStrategy
        self.memoryLevel = memoryLevel
    }
    
    public func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        
        guard let encodingMethod = request.accepts(header: "Accept-Encoding", types: ["gzip", "deflate", "identity"]), encodingMethod != "identity" else {
                Log.info("Not compressed: couldn't find acceptable encoding")
                next()
                return
        }
        
        var previousWrittenDataFilter: WrittenDataFilter? = nil
        let writtenDataFilter: WrittenDataFilter = { body in
            guard body.count > self.threshold else {
                Log.info("Not compressed: body \(body.count) is smaller than the threshold \(self.threshold)")
                return previousWrittenDataFilter!(body)
            }
            
            guard let compressed = self.compress(body, method: encodingMethod) else {
                Log.info("Not compressed: compression failed")
                return previousWrittenDataFilter!(body)
            }
            
            response.headers["Content-Encoding"] = encodingMethod
            response.headers["Content-Length"] = String(compressed.count)
            return previousWrittenDataFilter!(compressed)
        }
        previousWrittenDataFilter = response.setWrittenDataFilter(writtenDataFilter)
        
        next()
    }
    
    
    
    private func compress(_ inputData: Data, method: String) -> Data? {
        
        return inputData.withUnsafeBytes() { (bytes: UnsafePointer<Bytef>) -> Data? in
            let mutableBytes = UnsafeMutableRawPointer(mutating: bytes).assumingMemoryBound(to: Bytef.self)
            var stream = z_stream(next_in: mutableBytes,
                                  avail_in: uint(inputData.count),
                                  total_in: 0, next_out: nil, avail_out: 0,
                                  total_out: 0, msg: nil, state: nil, zalloc: nil,
                                  zfree: nil, opaque: nil, data_type: 0, adler: 0,
                                  reserved: 0)
        
            let windowBits = (method == "gzip") ? MAX_WBITS + 16 : MAX_WBITS
            guard deflateInit2_(&stream, compressionLevel.rawValue, Z_DEFLATED,
                                windowBits, memoryLevel, compressionStrategy.rawValue,
                                ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK else {
                return nil
            }
        
            var compressedData = Data()
            var compressBuffer = [Bytef](repeating: 0, count: chunkSize)
            while stream.avail_out == 0 {
                stream.next_out = UnsafeMutableRawPointer(mutating: compressBuffer).assumingMemoryBound(to: Bytef.self)
                stream.avail_out = uint(chunkSize)
            
                deflate(&stream, Z_FINISH)
                
                compressedData.append(&compressBuffer, count: chunkSize-Int(stream.avail_out))
            }
            deflateEnd(&stream)
            
            return compressedData
        }
    }
}

