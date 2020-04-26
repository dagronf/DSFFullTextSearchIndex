//
//  DSFFullTextSearchIndexTests.swift
//  DSFFullTextSearchIndex
//
//  Copyright © 2020 Darren Ford. All rights reserved.
//
//  MIT license
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial
//  portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//  WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
//  OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//  OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

@testable import DSFFullTextSearchIndex
import XCTest

final class DSFFullTextSearchIndexTests: XCTestCase {
	func testBasic() {
		let temp = DSFTemporaryFile()
		Swift.print(temp.tempFile.path)

		let index = DSFFullTextSearchIndex()
		XCTAssertEqual(.success, index.create(filePath: temp.tempFile.path))

		let url1 = URL(fileURLWithPath: "/tmp/blah")
		let url2 = URL(fileURLWithPath: "/tmp/blah2")
		let url3 = URL(fileURLWithPath: "/tmp/blah3")

		XCTAssertEqual(.success, index.add(url: url1, text: "This is a test bark"))
		XCTAssertEqual(1, index.count())

		XCTAssertEqual(.success, index.add(url: url2, text: "This is a caterpillar"))
		XCTAssertEqual(2, index.count())

		XCTAssertEqual(.success, index.add(url: url3, text: "bark bark bark"))
		XCTAssertEqual(3, index.count())

		let r = index.search(text: "test")!
		XCTAssertEqual(1, r.count)

		let r2 = index.search(text: "caterpillar")!
		XCTAssertEqual(1, r2.count)

		let r3 = index.search(text: "This")!
		XCTAssertEqual(2, r3.count)

		let r4 = index.search(text: "cat")!
		XCTAssertEqual(0, r4.count)

		let r5 = index.search(text: "cat*")!
		XCTAssertEqual(1, r5.count)

		let r6 = index.search(text: "bark")!
		XCTAssertEqual(2, r6.count)
		XCTAssertEqual(url3, r6[0])
		XCTAssertEqual(url1, r6[1])

		var urls = index.allURLs()
		XCTAssertEqual(3, urls.count)
		XCTAssertEqual(3, index.count())

		XCTAssertEqual(.success, index.remove(url: url3))
		let r7 = index.search(text: "bark")!
		XCTAssertEqual(1, r7.count)
		XCTAssertEqual(url1, r7[0])

		urls = index.allURLs()
		XCTAssertEqual(urls.count, 2)
	}

	func testDelete() {
		let temp = DSFTemporaryFile()
		Swift.print(temp.tempFile.path)

		let index = DSFFullTextSearchIndex()
		XCTAssertEqual(.success, index.create(filePath: temp.tempFile.path))

		let url1 = URL(fileURLWithPath: "/tmp/blah1")
		let url2 = URL(fileURLWithPath: "/tmp/blah2")
		let url3 = URL(fileURLWithPath: "/tmp/blah3")

		XCTAssertEqual(.success, index.add(url: url1, text: "This is a test bark"))
		XCTAssertEqual(.success, index.add(url: url2, text: "This is a caterpillar"))

		let r = index.search(text: "test")!
		XCTAssertEqual(1, r.count)

		let r2 = index.search(text: "caterpillar")!
		XCTAssertEqual(1, r2.count)

		XCTAssertTrue(index.exists(url: url2))
		XCTAssertFalse(index.exists(url: url3))

		XCTAssertEqual(.success, index.remove(url: url2))
		let r3 = index.search(text: "caterpillar")!
		XCTAssertEqual(0, r3.count)

		XCTAssertEqual(.success, index.remove(urls: [url2, url1]))
		let r4 = index.search(text: "caterpillar")!
		XCTAssertEqual(0, r4.count)
		let r5 = index.search(text: "test")!
		XCTAssertEqual(0, r5.count)

		////

		XCTAssertEqual(.success, index.add(url: url1, text: "This is a test bark"))
		XCTAssertEqual(.success, index.add(url: url2, text: "This is a caterpillar"))
		let r10 = index.search(text: "test")!
		XCTAssertEqual(1, r10.count)

		let r11 = index.search(text: "caterpillar")!
		XCTAssertEqual(1, r11.count)

		XCTAssertEqual(.success, index.removeAll())
		let r101 = index.search(text: "test")!
		XCTAssertEqual(0, r101.count)

		let r111 = index.search(text: "caterpillar")!
		XCTAssertEqual(0, r111.count)
	}

	func testChinese() {
		let temp = DSFTemporaryFile()
		Swift.print(temp.tempFile.path)

		let index = DSFFullTextSearchIndex()
		XCTAssertEqual(.success, index.create(filePath: temp.tempFile.path))

		let url1 = URL(fileURLWithPath: "/tmp/blah")
		let str1 = "为什么不支持中文 fts5 does not seem to work for chinese"

		XCTAssertEqual(.success, index.add(url: url1, text: str1))
		var r = index.search(text: "中文")!
		XCTAssertEqual(0, r.count)

		XCTAssertEqual(.success, index.add(url: url1, text: str1, useNativeEnumerator: true))
		r = index.search(text: "中文")!
		XCTAssertEqual(1, r.count)
		XCTAssertEqual(url1, r[0])

		let url2 = URL(fileURLWithPath: "/tmp/blah2")
		let str2 = "مرحبا العالم"
		XCTAssertEqual(.success, index.add(url: url2, text: str2))
		r = index.search(text: "العالم")!
		XCTAssertEqual(1, r.count)
		XCTAssertEqual(url2, r[0])
	}

	func testStopWords() {
		let temp = DSFTemporaryFile()
		Swift.print(temp.tempFile.path)

		let index = DSFFullTextSearchIndex()
		XCTAssertEqual(.success, index.create(filePath: temp.tempFile.path))

		let url1 = URL(fileURLWithPath: "/tmp/blah")
		XCTAssertEqual(.success, index.add(url: url1, text: "This is aren’t a caterpillar", stopWords: gStopWords))

		var r = index.search(text: "This")!
		XCTAssertEqual(0, r.count)
		r = index.search(text: "is")!
		XCTAssertEqual(0, r.count)
		r = index.search(text: "aren’t")!
		XCTAssertEqual(0, r.count)
		r = index.search(text: "are*")!
		XCTAssertEqual(0, r.count)
		r = index.search(text: "a")!
		XCTAssertEqual(0, r.count)
		r = index.search(text: "cater*")!
		XCTAssertEqual(1, r.count)
	}

	func testPhrasesAndNear() {
		let temp = DSFTemporaryFile()
		Swift.print(temp.tempFile.path)

		let index = DSFFullTextSearchIndex()
		XCTAssertEqual(.success, index.create(filePath: temp.tempFile.path))

		let url1 = URL(fileURLWithPath: "/tmp/blah")
		XCTAssertEqual(.success, index.add(url: url1, text: "Sphinx of black quartz judge my vow"))

		var r = index.search(text: "QUARTZ")!
		XCTAssertEqual(1, r.count)

		r = index.search(text: "black + quartz")!
		XCTAssertEqual(1, r.count)

		r = index.search(text: "Sphinx + quartz")!
		XCTAssertEqual(0, r.count)

		r = index.search(text: "Sphinx of")!
		XCTAssertEqual(1, r.count)

		r = index.search(text: "NEAR(sphinx quartz)")!
		XCTAssertEqual(1, r.count)

		r = index.search(text: "NEAR(sphinx judge, 2)")!
		XCTAssertEqual(0, r.count)

		r = index.search(text: "NEAR(sphinx judge, 3)")!
		XCTAssertEqual(1, r.count)
	}

	func testChinese2() {
		let str1 = """
		　　盖闻天地之数，有十二万九千六百岁为一元。将一元分为十二会，乃子、丑
		、寅、卯、辰、巳、午、未、申、酉、戌、亥之十二支也。每会该一万八百岁。
		且就一日而论：子时得阳气，而丑则鸡鸣；寅不通光，而卯则日出；辰时食后，
		而巳则挨排；日午天中，而未则西蹉；申时晡而日落酉；戌黄昏而人定亥。譬于
		大数，若到戌会之终，则天地昏蒙而万物否矣。再去五千四百岁，交亥会之初，
		则当黑暗，而两间人物俱无矣，故曰混沌。又五千四百岁，亥会将终，贞下起元
		，近子之会，而复逐渐开明。邵康节曰：“冬至子之半，天心无改移。一阳初动
		处，万物未生时。”到此，天始有根。再五千四百岁，正当子会，轻清上腾，有
		日，有月，有星，有辰。日、月、星、辰，谓之四象。故曰，天开于子。又经五
		千四百岁，子会将终，近丑之会，而逐渐坚实。易曰：“大哉乾元！至哉坤元！
		万物资生，乃顺承天。”至此，地始凝结。再五千四百岁，正当丑会，重浊下凝
		，有水，有火，有山，有石，有土。水、火、山、石、土谓之五形。故曰，地辟
		于丑。又经五千四百岁，丑会终而寅会之初，发生万物。历曰：“天气下降，地
		气上升；天地交合，群物皆生。”至此，天清地爽，阴阳交合。再五千四百岁，
		正当寅会，生人，生兽，生禽，正谓天地人，三才定位。故曰，人生于寅。
		"""

		let temp = DSFTemporaryFile()
		Swift.print(temp.tempFile.path)

		let index = DSFFullTextSearchIndex()
		XCTAssertEqual(.success, index.create(filePath: temp.tempFile.path))

		let url1 = URL(fileURLWithPath: "/tmp/blah")
		XCTAssertEqual(.success, index.add(url: url1, text: str1, useNativeEnumerator: true))

		let r = index.search(text: "天地")!
		XCTAssertEqual(1, r.count)
		XCTAssertEqual(url1, r[0])
	}


	func testCreateOpen() {
		let temp = DSFTemporaryFile()
		Swift.print(temp.tempFile.path)

		let index = DSFFullTextSearchIndex()
		XCTAssertEqual(.success, index.create(filePath: temp.tempFile.path))

		let url1 = URL(string: "demo://maintext/1")!
		XCTAssertEqual(.success, index.add(url: url1, text: "Sphinx of black quartz judge my vow"))

		let url2 = URL(string: "demo://maintext/2")!
		XCTAssertEqual(.success, index.add(url: url2, text: "Quick brown fox jumps over the lazy dog"))

		let url3 = URL(string: "demo://maintext/3")!
		XCTAssertEqual(.success, index.add(url: url3, text: "The dog didn't like the bird sitting on the fence and left quietly"))

		let urls1 = index.search(text: "quartz")!   // single match - url1
		XCTAssertEqual(1, urls1.count)
		let urls2 = index.search(text: "quick")!    // single match - url2
		XCTAssertEqual(1, urls2.count)
		let urls3 = index.search(text: "dog")!      // two matches - url1 and url3
		XCTAssertEqual(2, urls3.count)

		index.close()

		let index2 = DSFFullTextSearchIndex()

		XCTAssertEqual(.success, index2.open(filePath: temp.tempFile.path))
		let urls11 = index2.search(text: "quartz")!   // single match - url1
		XCTAssertEqual(1, urls11.count)
		let urls12 = index2.search(text: "quick")!    // single match - url2
		XCTAssertEqual(1, urls12.count)
		let urls13 = index2.search(text: "dog")!      // two matches - url1 and url3
		XCTAssertEqual(2, urls13.count)

		index.close()
	}

	static var allTests = [
		("testBasic", testBasic),
		("testDelete", testDelete),
		("testChinese", testChinese),
		("testStopWords", testStopWords),
		("testPhrasesAndNear", testPhrasesAndNear),
		("testChinese2", testChinese2),
		("testCreateOpen", testCreateOpen),
	]
}
