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

import XCTest
import Foundation
import Kitura

@testable import KituraCompression

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

class TestCompression : XCTestCase {

    static var allTests : [(String, (TestCompression) -> () throws -> Void)] {
        return [
            ("testGzipCompression", testGzipCompression),
            ("testDeflateCompression", testDeflateCompression),
            ("testNoCompression", testNoCompression),
        ]
    }

    override func tearDown() {
        doTearDown()
    }

    let router = TestCompression.setupRouter()
    
    static let body1 = "Shall I compare thee to a summer's day? Thou art more lovely and more temperate: Rough winds do shake the darling buds of May, And summer's lease hath all too short a date:"
    
    static let body2 = "Sometime too hot the eye of heaven shines"

    static let compressedBodyGzip = "H4sIAAAAAAAAAz2OMQ4CMQwEv7IdDS+gQZQUNMAHDDHnE058ShxQfo8PJBpLlndmfRFSxRF3ywtVhgvHMBBaz5nrpiHR2OMq1kHVkS1Sai/WASrptzvnhSs573C2Pgnec0lBGprQ82sNTdW5TLj1uNgDJxpbHMLwL1KmxhBywfqU24pbdFLA4f4Atgml9qwAAAA="

    static let compressedBodyDeflate = "eJw9jjEOAjEMBL+yHQ0voEGUFDTABwwx5xNOfEocUH6PDyQaS5Z3Zn0RUsURd8sLVYYLxzAQWs+Z66Yh0djjKtZB1ZEtUmov1gEq6bc754UrOe9wtj4J3nNJQRqa0PNrDU3VuUy49bjYAycaWxzC8C9SpsYQcsH6lNuKW3RSwOH+AJYbPMU="
    
    func testGzipCompression() {
    	performServerTest(router) { expectation in
            self.performRequest("get", path:"/sonnet18/1", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let encoding = response!.headers["Content-Encoding"] where encoding.count > 0 else {
                    XCTFail("No encoding")
                    return
                }
                XCTAssertEqual(encoding[0], "gzip")
                do {
                    let body = NSMutableData()
                    guard try response!.readAllData(into: body) > 0 else {
                        XCTFail("No response body")
                        return
                    }
                    XCTAssertEqual(body.base64EncodedString([]), TestCompression.compressedBodyGzip)
                }
                catch{
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }, headers: ["Accept-encoding": "gzip, deflate"])
        }
    }

    func testDeflateCompression() {
        performServerTest(router) { expectation in
            self.performRequest("get", path:"/sonnet18/1", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                guard let encoding = response!.headers["Content-Encoding"] where encoding.count > 0 else {
                    XCTFail("No encoding")
                    return
                }
                XCTAssertEqual(encoding[0], "deflate")
                do {
                    let body = NSMutableData()
                    guard try response!.readAllData(into: body) > 0 else {
                        XCTFail("No response body")
                        return
                    }
                    XCTAssertEqual(body.base64EncodedString([]), TestCompression.compressedBodyDeflate)
                }
                catch{
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }, headers: ["Accept-encoding": "deflate"])
        }
    }

    func testNoCompression() {
        performServerTest(router) { expectation in
            self.performRequest("get", path:"/sonnet18/2", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertNil(response!.headers["Content-Encoding"], "Short message was compressed")
                do {
                    guard let body = try response!.readString() else {
                        XCTFail("No response body")
                        return
                    }
                    XCTAssertEqual(body, TestCompression.body2)
                }
                catch{
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }, headers: ["Accept-encoding": "gzip, deflate"])
        }
    }

    static func setupRouter() -> Router {
        let router = Router()

        router.all(middleware: Compression(threshold: 100))
        router.get("/sonnet18/1") { _, response, next in
            do {
                try response.end(body1)
            }
            catch {}
            next()
        }
        
        router.get("/sonnet18/2") { _, response, next in
            do {
                try response.end(body2)
            }
            catch {}
            next()
        }

        return router
    }
}
