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
    
    public init (threshold: Int = 1024, chunkSize: Int = 16384, compressionLevel: CompressionLevel = CompressionLevel.defaultCompression, compressionStrategy: CompressionStrategy = CompressionStrategy.defaultStrategy, memoryLevel: Int32 = 8) {
        self.threshold = threshold
        self.chunkSize = chunkSize
        self.compressionLevel = compressionLevel
        self.compressionStrategy = compressionStrategy
        self.memoryLevel = memoryLevel
    }
    
    public func handle(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        
        guard let encodingMethod = request.accepts(header: "Accept-Encoding", types: ["gzip", "deflate", "identity"])
            where encodingMethod != "identity" else {
                Log.info("Not compressed: couldn't find acceptable encoding")
                next()
                return
        }
        
        var previousWrittenDataFilter: WrittenDataFilter? = nil
        let writtenDataFilter: WrittenDataFilter = { body in
            guard body.length > self.threshold else {
                Log.info("Not compressed: body \(body.length) is smaller than the threshold \(self.threshold)")
                return previousWrittenDataFilter!(body: body)
            }
            
            guard let compressed = self.compress(NSMutableData(data: body), method: encodingMethod, response: response) else {
                Log.info("Not compressed: compression failed")
                return previousWrittenDataFilter!(body: body)
            }
            
            return previousWrittenDataFilter!(body: compressed)
        }
        previousWrittenDataFilter = response.setWrittenDataFilter(writtenDataFilter)
        
        next()
    }
    
    
    
    private func compress(_ inputData: NSMutableData, method: String, response: RouterResponse) -> NSData? {
        var stream = z_stream(next_in: UnsafeMutablePointer<Bytef>(inputData.bytes), avail_in: uint(inputData.length), total_in: 0, next_out: nil, avail_out: 0, total_out: 0, msg: nil, state: nil, zalloc: nil, zfree: nil, opaque: nil, data_type: 0, adler: 0, reserved: 0)
        
        let windowBits = (method == "gzip") ? MAX_WBITS + 16 : MAX_WBITS
        guard deflateInit2_(&stream, compressionLevel.rawValue, Z_DEFLATED, windowBits, memoryLevel, compressionStrategy.rawValue, ZLIB_VERSION, Int32(sizeof(z_stream))) == Z_OK else {
            return nil
        }
        
        let compressedData = NSMutableData(length: chunkSize)!
        while stream.avail_out == 0 {
            if Int(stream.total_out) >= compressedData.length {
                compressedData.length += chunkSize
            }
            
            stream.next_out = UnsafeMutablePointer<Bytef>(compressedData.mutableBytes).advanced(by: Int(stream.total_out))
            stream.avail_out = uInt(compressedData.length) - uInt(stream.total_out)
            
            deflate(&stream, Z_FINISH)
        }
        deflateEnd(&stream)
        
        compressedData.length = Int(stream.total_out)
        response.headers["Content-Encoding"] = method
        response.headers["Content-Length"] = String(compressedData.length)
        return NSData(data: compressedData)
    }
}

