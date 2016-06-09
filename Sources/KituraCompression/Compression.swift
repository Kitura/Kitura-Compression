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

    // windowBits, memoryLevel
    
    public init (threshold: Int = 1024, chunkSize: Int = 16384, compressionLevel: CompressionLevel = CompressionLevel.defaultCompression, compressionStrategy : CompressionStrategy = CompressionStrategy.defaultStrategy) {
        self.threshold = threshold
        self.chunkSize = chunkSize
        self.compressionLevel = compressionLevel
        self.compressionStrategy = compressionStrategy
    }
    
    public func handle(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        
        guard let encodingMethod = request.accepts(header: "Accept-Encoding", types: ["gzip", "deflate", "identity"])
            where encodingMethod != "identity" else {
                Log.info("Not compressed: couldn't find acceptable encoding")
                next()
                return
        }
        // prefer gzip over deflate?
        
        var previousPreWriteHandler: PreWriteLifecycleHandler? = nil
        let preWriteHandler: PreWriteLifecycleHandler = { body, request, response in
            guard body.length > self.threshold else {
                Log.info("Not compressed: body \(body.length) is smaller than the threshold \(self.threshold)")
                return previousPreWriteHandler!(body: body, request: request, response: response)
            }

            guard let compressed = self.compress(NSMutableData(data: body), method: encodingMethod) else {
                Log.info("Not compressed: compression failed")
                return previousPreWriteHandler!(body: body, request: request, response: response)
            }
            
            response.headers["Content-Encoding"] = encodingMethod
            
            return previousPreWriteHandler!(body: compressed, request: request, response: response)
        }
        previousPreWriteHandler = response.setPreWriteHandler(preWriteHandler)
        
        next()
    }
    
    
    private let STREAM_SIZE: Int32 = Int32(sizeof(z_stream))
    
    private func compress(_ inputData: NSMutableData, method: String) -> NSData? {
        
        guard method == "gzip" else { // FORNOW
            return nil
        }
        
        var stream = z_stream(next_in: UnsafeMutablePointer<Bytef>(inputData.bytes), avail_in: uint(inputData.length), total_in: 0, next_out: nil, avail_out: 0, total_out: 0, msg: nil, state: nil, zalloc: nil, zfree: nil, opaque: nil, data_type: 0, adler: 0, reserved: 0)

        guard deflateInit2_(&stream, compressionLevel.rawValue, Z_DEFLATED, MAX_WBITS + 16, MAX_MEM_LEVEL, compressionStrategy.rawValue, ZLIB_VERSION, STREAM_SIZE) == Z_OK else {
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
        
        return NSData(data: compressedData)
    }
}

