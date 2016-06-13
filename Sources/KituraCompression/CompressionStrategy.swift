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

public enum CompressionStrategy: Int32 {
    case defaultStrategy = 0, filtered, huffmanOnly, rle, fixed
}

//#define Z_FILTERED            1
//#define Z_HUFFMAN_ONLY        2
//#define Z_RLE                 3
//#define Z_FIXED               4
//#define Z_DEFAULT_STRATEGY    0
