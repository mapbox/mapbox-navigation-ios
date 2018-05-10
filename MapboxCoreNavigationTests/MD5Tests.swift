import XCTest
@testable import MapboxCoreNavigation

class Tests: XCTestCase {
    
    func testMD5() {
        XCTAssertEqual("hello".md5(),
                       "5d41402abc4b2a76b9719d911017c592")
        XCTAssertEqual("world".md5(),
                       "7d793037a0760186574b0282f2f435e7")
        XCTAssertEqual("https://www.google.com".md5(),
                       "8ffdefbdec956b595d257f0aaeefd623")
        XCTAssertEqual("https://www.google.com/logos/doodles/2016/parents-day-in-korea-5757703554072576-hp2x.jpg".md5(),
                       "0dfb10e8d2ae771b3b3ed4544139644e")
        XCTAssertEqual("https://unsplash.it/600/300/?image=1".md5(),
                       "d59e956ebb1be415970f04ec77f4c875")
        XCTAssertEqual("".md5(),
                       "d41d8cd98f00b204e9800998ecf8427e")
        XCTAssertEqual("ABCDEFGHIJKLMNOPQRSTWXYZ1234567890".md5(),
                       "b8f4f38629ec4f4a23f5dcc6086f8035")
        XCTAssertEqual("abcdefghijklmnopqrstwxyz1234567890".md5(),
                       "b2e875f4d53ccf6cefb5cda3f86fc542")
        XCTAssertEqual("0123456789".md5(),
                       "781e5e245d69b566979b86e28d23f2c7")
        XCTAssertEqual("0".md5(),
                       "cfcd208495d565ef66e7dff9f98764da")
        XCTAssertEqual("https://twitter.com/_HairForceOne/status/745235759460810752".md5(),
                       "40c2bfa3d7bfc7a453013ecd54022255")
        XCTAssertEqual("Det er et velkjent faktum at lesere distraheres av lesbart innhold på en side når man ser på dens layout. Poenget med å bruke Lorem Ipsum er at det har en mer eller mindre normal fordeling av bokstaver i ord, i motsetning til 'Innhold her, innhold her', og gir inntrykk av å være lesbar tekst. Mange webside- og sideombrekkingsprogrammer bruker nå Lorem Ipsum som sin standard for provisorisk tekst".md5(),
                       "6b2880bcc7554cf07e72db9c99bf3284")
        XCTAssertEqual("\\".md5(),
                       "28d397e87306b8631f3ed80d858d35f0")
        XCTAssertEqual("http://res.cloudinary.com/demo/image/upload/w_300,h_200,c_crop/sample.jpg".md5(),
                       "6e30d9cc4c08be4eea49076328d4c1f0")
        XCTAssertEqual("http://res.cloudinary.com/demo/image/upload/x_355,y_410,w_300,h_200,c_crop/brown_sheep.jpg".md5(),
                       "019e9d72b5af84ef114868875c1597ed")
        XCTAssertEqual("http://www.w3schools.com/tags/html_form_submit.asp?text=Hello+G%C3%BCnter".md5(),
                       "c89a2146cd3df34ecda86b6e0709b3fd")
        XCTAssertEqual("!%40%23%24%25%5E%26*()%2C.%3C%3E%5C'1234567890-%3D".md5(),
                       "09a1790760693160e74b9d6fcec7ef64")
        XCTAssertEqual("🛡".md5(),
                       "a11d9c95b5bcb5687f10bad109131f20")
    }
    
    func testMD5_Data() {
        let data = "https://www.google.com".data(using: String.Encoding.utf8)
        XCTAssertEqual(String(data: data!, encoding: String.Encoding.utf8)!.md5(),
                       "8ffdefbdec956b595d257f0aaeefd623")
    }
    
    func testNaughtyStrings() {
        let path = Bundle(for: Tests.self).path(forResource: "md5_crazy_strings", ofType: "txt")!
        let content = try! String(contentsOfFile: path, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        
        lines.forEach { line in
            let md5 = line.md5()
            XCTAssertEqual(md5.count, 32)
        }
    }
}
