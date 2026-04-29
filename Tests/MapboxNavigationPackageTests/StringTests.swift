@testable import MapboxNavigationUIKit
import TestHelper
import XCTest

class StringTests: TestCase {
    func testSH256() {
        XCTAssertEqual("hello".sha256, "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
        XCTAssertEqual("world".sha256, "486ea46224d1bb4fb680f34f7c9ad96a8f24ec88be73ea8e5a6c65260e9cb8a7")
        XCTAssertEqual(
            "https://www.google.com".sha256,
            "ac6bb669e40e44a8d9f8f0c94dfc63734049dcf6219aac77f02edf94b9162c09"
        )
        XCTAssertEqual(
            "https://www.google.com/logos/doodles/2016/parents-day-in-korea-5757703554072576-hp2x.jpg".sha256,
            "cb051d58a60b9581ff4c7ba63da07f9170f61bfbebab4a39898432ec970c3754"
        )
        XCTAssertEqual(
            "https://unsplash.it/600/300/?image=1".sha256,
            "1b93ff9cf0d84ef517932cf34c32cae978efa54fa6515ac539ce4d5c8d8dabe6"
        )
        XCTAssertEqual("".sha256, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertEqual(
            "ABCDEFGHIJKLMNOPQRSTWXYZ1234567890".sha256,
            "6d5fdadafcf2a24f9ac8140071a6d6cdc56457adfe3352adf7b0a1aad8fe59f5"
        )
        XCTAssertEqual(
            "abcdefghijklmnopqrstwxyz1234567890".sha256,
            "cdf62fb9624f761e842e7af78d7c25e3fac7758db20d1bd4d1e5cdb8fa99c2e3"
        )
        XCTAssertEqual("0123456789".sha256, "84d89877f0d4041efb6bf91a16f0248f2fd573e6af05c19f96bedb9f882f7882")
        XCTAssertEqual("0".sha256, "5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9")
        XCTAssertEqual(
            "https://twitter.com/_HairForceOne/status/745235759460810752".sha256,
            "e73ff3865f78893d0559d8ecfb1aeae16956cd07b2754f3ed4d8994f9ebd30df"
        )
        XCTAssertEqual(
            "Det er et velkjent faktum at lesere distraheres av lesbart innhold på en side når man ser på dens layout. Poenget med å bruke Lorem Ipsum er at det har en mer eller mindre normal fordeling av bokstaver i ord, i motsetning til 'Innhold her, innhold her', og gir inntrykk av å være lesbar tekst. Mange webside- og sideombrekkingsprogrammer bruker nå Lorem Ipsum som sin standard for provisorisk tekst"
                .sha256,
            "27f963d2834df1ff1677027c4712158f437773b8a1af2b5f73db3f4051780c4a"
        )
        XCTAssertEqual("\\".sha256, "a9253dc8529dd214e5f22397888e78d3390daa47593e26f68c18f97fd7a3876b")
        XCTAssertEqual(
            "http://res.cloudinary.com/demo/image/upload/w_300,h_200,c_crop/sample.jpg".sha256,
            "55046323acbb9aa16ed130fb372790a055c6aafd9a5a7b0a2b8ba8c5c7ed2d40"
        )
        XCTAssertEqual(
            "http://res.cloudinary.com/demo/image/upload/x_355,y_410,w_300,h_200,c_crop/brown_sheep.jpg".sha256,
            "3ac1011676e13f8f6d73d4ea9705fe6633bda6613c4c28d648f994c8ea72b4fc"
        )
        XCTAssertEqual(
            "http://www.w3schools.com/tags/html_form_submit.asp?text=Hello+G%C3%BCnter".sha256,
            "bea84e8c1aea1a1b40b164266d734d29bee401225ed1bcfef5c33412f48ffda3"
        )
        XCTAssertEqual(
            "!%40%23%24%25%5E%26*()%2C.%3C%3E%5C'1234567890-%3D".sha256,
            "fb39bbc182142036634303ff7a78690ae0b3da3f40a67f67d80b773471edff7b"
        )
        XCTAssertEqual("🛡".sha256, "b44793a1df6cc2d26458bc8f2db2094acc9885c1a390bf1b3b743bc5167adfe5")
    }

    func testSHA256_Data() {
        let data = "https://www.google.com".data(using: String.Encoding.utf8)
        XCTAssertEqual(
            String(data: data!, encoding: String.Encoding.utf8)!.sha256,
            "ac6bb669e40e44a8d9f8f0c94dfc63734049dcf6219aac77f02edf94b9162c09"
        )
    }

    func testNaughtyStrings() {
        let path = Fixture.bundle.path(forResource: "encoding_crazy_strings", ofType: "txt")!
        let content = try! String(contentsOfFile: path, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        lines.forEach { line in
            let sha256 = line.sha256
            XCTAssertEqual(sha256.count, 64)
        }
    }
}
