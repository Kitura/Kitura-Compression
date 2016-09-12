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

// MARK CompressionStrategy

/// The strategy parameter of zlib compression.
/// The strategy is used to tune the compression algorithm, it affects the 
/// compression ratio but not the correctness of the compressed output.
/// For more information, see [zlib manual](http://www.zlib.net/manual.html).
public enum CompressionStrategy: Int32 {
    
    /// The default strategy (for normal data).
    case defaultStrategy = 0
    
    /// Force more Huffman coding and less string matching.
    case filtered
    
    /// Force Huffman encoding only (no string match).
    case huffmanOnly
    
    /// Limit match distances to one (run-length encoding)
    case rle
    
    /// Prevent the use of dynamic Huffman codes.
    case fixed
}
