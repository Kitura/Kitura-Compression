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

// MARK CompressionLevel

/// The level of zlib compression to apply.
/// For more information, see [zlib manual](http://www.zlib.net/manual.html).
public enum CompressionLevel: Int32 {
    /// No compression is performed - the input data is simply copied a block at a time.
    case noCompression = 0
    /// Best speed.
    case bestSpeed = 1
    /// Best compression.
    case bestCompression = 9
    /// A compromise between speed and compression.
    case defaultCompression = -1 
}
