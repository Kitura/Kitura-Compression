# Kitura-Compression
Kitura compression middleware

[![Build Status - Master](https://travis-ci.org/IBM-Swift/Kitura.svg?branch=master)](https://travis-ci.org/IBM-Swift/Kitura-Compression)
![Mac OS X](https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

## Summary
Kitura compression middleware. Supports `deflate` and `gzip` compression methods. Uses [zlib](http://zlib.net/).


## Table of Contents
* [Swift version](#swift-version)
* [API](#api)
* [License](#license)

## Swift version
The latest version of Kitura-Compression works with the DEVELOPMENT-SNAPSHOT-2016-05-09-a version of the Swift binaries. You can download this version of the Swift binaries by following this [link](https://swift.org/download/). Compatibility with other Swift versions is not guaranteed.


## API
In order to use compression middleware, create an instance of `Compression`, and connect it to the desired path:

```swift
import KituraCompression

router.all(middleware: Compression())
```
You can configure `Compression` with optional arguments:
```swift
    public init (threshold: Int = 1024, chunkSize: Int = 16384, compressionLevel: CompressionLevel = CompressionLevel.defaultCompression, compressionStrategy: CompressionStrategy = CompressionStrategy.defaultStrategy, memoryLevel: Int32 = 8)
```
**Where:**
   - *threshold* is the byte threshold for the response body size before compression is considered for the response, defaults to 1024.
   - *chunkSize* is the size of internal output slab buffer in bytes, defaults to 16384
   - *compressionLevel* is the level of zlib compression to apply. The supported levels are:
 ```c  
#define Z_NO_COMPRESSION         0
#define Z_BEST_SPEED             1
#define Z_BEST_COMPRESSION       9
#define Z_DEFAULT_COMPRESSION  (-1)
  ```
   - *compressionStrategy* is is used to tune the compression algorithm. Here are its possible values:
   ```c
#define Z_FILTERED            1
#define Z_HUFFMAN_ONLY        2
#define Z_RLE                 3
#define Z_FIXED               4
#define Z_DEFAULT_STRATEGY    0
```
   - *memoryLevel* specifies how much memory should be allocated
   for the internal compression state. The default value is 8.

For more information on compression parameters, see  [zlib manual](http://www.zlib.net/manual.html).



## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE.txt).
