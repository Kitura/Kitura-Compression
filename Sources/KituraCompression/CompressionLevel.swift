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

// import CZlib

public enum CompressionLevel: Int32 {
    case noCompression = 0       // Z_NO_COMPRESSION
    case bestSpeed = 1           // Z_BEST_SPEED
    case bestCompression = 9     // Z_BEST_COMPRESSION
    case defaultCompression = -1 // Z_DEFAULT_COMPRESSION
}
/*
 public struct CompressionLevel: Int32 {
 var noCompression:Int32 {
 get {
 return Z_NO_COMPRESSION
 }
 }
 var bestSpeed:Int32 {
 get {
 return Z_BEST_SPEED
 }
 }
 var bestCompression:Int32 {
 get {
 return Z_BEST_COMPRESSION
 }
 }
 var defaultCompression:Int32 {
 get {
 return Z_DEFAULT_COMPRESSION
 }
 }
 
 }
 */