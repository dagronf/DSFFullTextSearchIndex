//
//  DSFFullTextSearchIndex.swift
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

import Foundation
import SQLite3

/// A full text search class using sqlite FTS5 as the text indexer
@objc public class DSFFullTextSearchIndex: NSObject {

	private static var TableDef = "textFTS"
	private var db: OpaquePointer?

	/// Error states
	@objc(DSFSearchIndexStatus) public enum Status: Int {
		case success = 0

		case fileAlreadyExists = -1
		case documentUrlAlreadyExists = -2

		case sqliteUnableToOpen = -100
		case sqliteUnableToPrepare = -101
		case sqliteUnableToBind = -102
		case sqliteUnableToStep = -103
	}

	/// Create a search index to a file on disk
	/// - Parameter fileURL: the file URL specifying the index file to create
	/// - Returns: true if created successfully, false otherwise
	@objc public func create(fileURL: URL) -> Status {
		return self.create(filePath: fileURL.path)
	}

	/// Create a search index to a file on disk
	/// - Parameter path: the file path specifying the index file to create
	/// - Returns: true if created successfully, false otherwise
	@objc public func create(filePath: String) -> Status {
		self.close()
		return self.createDatabase(filePath: filePath)
	}

	/// Open a search index from a file on disk
	/// - Parameter fileURL: the file URL specifying the index to open
	/// - Returns: true if opened successfully, false otherwise
	@objc public func open(fileURL: URL) -> Status {
		return self.open(filePath: fileURL.path)
	}

	/// Open a search index from a file on disk
	/// - Parameter path: the file path specifying the index to open
	/// - Returns: true if opened successfully, false otherwise
	@objc public func open(filePath: String) -> Status {
		self.close()
		if sqlite3_open(filePath, &db) != SQLITE_OK {
			print("Error opening database")
			return .sqliteUnableToOpen
		}
		return .success
	}

	/// Close the search index
	@objc public func close() {
		if let d = db {
			sqlite3_close(d)
			db = nil
		}
	}
}

// MARK: - Adding documents

extension DSFFullTextSearchIndex {

	/// Add a new document to the search index
	/// - Parameters:
	///   - url: The unique URL identifying the document
	///   - text: The document text
	///   - canReplace: Allow or disallow replacing a document with an identical URL
	///   - useNativeEnumerator: If true, uses the native text enumerator methods to split into words before adding to index.  Can improve word searching for CJK texts
	///   - stopWords: If set, removes any words in the set from the document before adding to the index
	/// - Returns: true if the document was successfully added to the index, false otherwise
	@objc public func add(url: URL, text: String, canReplace: Bool = true, useNativeEnumerator: Bool = false, stopWords: Set<String>? = nil) -> Status {

		// If we're not allowed to replace, check whether the url exists first
		if !canReplace, self.exists(url: url) {
			return .documentUrlAlreadyExists
		}

		let urlString: NSString = url.absoluteString as NSString

		let textString = NSMutableString(capacity: text.count)

		// We can use the built-in string enumerator in macOS/iOS/tvOS to split words before adding to index
		// This is useful when indexing something like CJK text, where words aren't necessarily separated by spaces
		// The built-in fts tokenisers in sqlite doesn't seem to handle these cases well.
		if useNativeEnumerator || stopWords != nil {
			let nsText = text as NSString
			let stops = stopWords ?? Set<String>()
			nsText.enumerateSubstrings(in: NSRange(location: 0, length: nsText.length), options: [.byWords]) { str, _, _, _ in
				if let str = str?.lowercased(), !stops.contains(str) {
					textString.append("\(str) ")
				}
			}
		} else {
			textString.append(text)
		}

		let insertStatement = "INSERT INTO \(DSFFullTextSearchIndex.TableDef) (url, content) VALUES (?,?);"

		var stmt: OpaquePointer?
		defer {
			sqlite3_finalize(stmt)
		}

		guard sqlite3_prepare(self.db, insertStatement, -1, &stmt, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			Swift.print("error preparing insert: \(errmsg)")
			return .sqliteUnableToPrepare
		}

		guard sqlite3_bind_text(stmt, 1, urlString.utf8String, -1, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			Swift.print("failure binding name: \(errmsg)")
			return .sqliteUnableToBind
		}

		guard sqlite3_bind_text(stmt, 2, textString.utf8String, -1, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			Swift.print("failure binding name: \(errmsg)")
			return .sqliteUnableToBind
		}

		guard sqlite3_step(stmt) == SQLITE_DONE else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			Swift.print("failure inserting hero: \(errmsg)")
			return .sqliteUnableToStep
		}

		return .success
	}
}

// MARK: - Removing documents

extension DSFFullTextSearchIndex {

	/// Remove the specified document from the search index
	@objc public func remove(url: URL) -> Status {
		return self.remove(urls: [url])
	}

	/// Remove the specified documents from the search index
	@objc public func remove(urls: [URL]) -> Status {
		let urlsPlaceholder = urls.map { _ in "?" }.joined(separator: ",")
		let deleteStatement = "DELETE FROM \(DSFFullTextSearchIndex.TableDef) where url IN (\(urlsPlaceholder));"

		var stmt: OpaquePointer?
		defer {
			sqlite3_finalize(stmt)
		}

		guard sqlite3_prepare(self.db, deleteStatement, -1, &stmt, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			Swift.print("error preparing delete: \(errmsg)")
			return .sqliteUnableToPrepare
		}

		for count in 1 ... urls.count {
			let urlString = urls[count - 1].absoluteString as NSString
			guard sqlite3_bind_text(stmt, Int32(count), urlString.utf8String, -1, nil) == SQLITE_OK else {
				let errmsg = String(cString: sqlite3_errmsg(self.db)!)
				Swift.print("failure binding name: \(errmsg)")
				return .sqliteUnableToBind
			}
		}

		guard sqlite3_step(stmt) == SQLITE_DONE else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			Swift.print("failure deleting url \(urls): \(errmsg)")
			return .sqliteUnableToStep
		}

		return .success
	}

	/// Remove all documents in the search index
	@objc public func removeAll() -> Status {
		let deleteStatement = "DELETE FROM \(DSFFullTextSearchIndex.TableDef)"
		var stmt: OpaquePointer?
		defer {
			sqlite3_finalize(stmt)
		}
		guard sqlite3_prepare(self.db, deleteStatement, -1, &stmt, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			Swift.print("error preparing delete: \(errmsg)")
			return .sqliteUnableToPrepare
		}
		guard sqlite3_step(stmt) == SQLITE_DONE else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			Swift.print("failure removing all urls: \(errmsg)")
			return .sqliteUnableToStep
		}
		return .success
	}
}

// MARK: - Content information

extension DSFFullTextSearchIndex {

	/// Returns true if the specified document url exists in the search index, false otherwise
	@objc public func exists(url: URL) -> Bool {
		let query = "SELECT url FROM \(DSFFullTextSearchIndex.TableDef) where url = ?"

		var statement: OpaquePointer?
		defer {
			sqlite3_finalize(statement)
		}

		guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			fatalError("Error preparing select: \(errmsg)")
		}

		let urlString: NSString = url.absoluteString as NSString
		guard sqlite3_bind_text(statement, 1, urlString.utf8String, -1, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			fatalError("failure binding name: \(errmsg)")
		}

		return sqlite3_step(statement) == SQLITE_ROW
	}

	/// Returns all the document URLs stored in the index
	@objc public func allURLs() -> [URL] {
		let query = "SELECT url FROM \(DSFFullTextSearchIndex.TableDef)"

		var statement: OpaquePointer?
		defer {
			sqlite3_finalize(statement)
		}

		guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			fatalError("Error preparing select: \(errmsg)")
		}

		var results = [URL]()
		while sqlite3_step(statement) == SQLITE_ROW {
			guard let cURL = sqlite3_column_text(statement, 0) else {
				continue
			}
			let urlString = String(cString: cURL)
			guard let url = URL(string: urlString) else {
				continue
			}
			results.append(url)
		}
		return results
	}

	/// Returns the number of documents in the search index
	@objc public func count() -> Int32 {
		let query = "SELECT COUNT(*) FROM \(DSFFullTextSearchIndex.TableDef)"

		var statement: OpaquePointer?
		defer {
			sqlite3_finalize(statement)
		}

		guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			fatalError("Error preparing select: \(errmsg)")
		}

		guard sqlite3_step(statement) == SQLITE_ROW else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			fatalError("Error preparing select: \(errmsg)")
		}

		return sqlite3_column_int(statement, 0)
	}
}

// MARK: - Search

extension DSFFullTextSearchIndex {

	/// Perform a text search using the current index
	/// - Parameter text: The text to search for
	/// - Returns: An array of document URLs matching the text query
	@objc public func search(text: String) -> [URL]? {
		let query = """
		SELECT url FROM \(DSFFullTextSearchIndex.TableDef)
		WHERE \(DSFFullTextSearchIndex.TableDef) MATCH ? ORDER BY bm25(\(DSFFullTextSearchIndex.TableDef))
		"""

		var statement: OpaquePointer?
		defer {
			sqlite3_finalize(statement)
		}

		if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
			print("Error preparing select: \(String(cString: sqlite3_errmsg(db)!))")
			return nil
		}

		let textString = text as NSString
		guard sqlite3_bind_text(statement, 1, textString.utf8String, -1, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			Swift.print("failure binding name: \(errmsg)")
			return nil
		}

		var results = [URL]()
		while sqlite3_step(statement) == SQLITE_ROW {
			guard let cURL = sqlite3_column_text(statement, 0) else {
				continue
			}
			let urlString = String(cString: cURL)
			guard let url = URL(string: urlString) else {
				continue
			}
			results.append(url)
		}

		return results
	}
}

private extension DSFFullTextSearchIndex {
	func createDatabase(filePath: String) -> Status {
		if FileManager.default.fileExists(atPath: filePath) {
			return .fileAlreadyExists
		}

		if sqlite3_open(filePath, &db) != SQLITE_OK {
			print("Error opening database")
			return .sqliteUnableToOpen
		}
		return createTables()
	}

	func createTables() -> Status {
		let createTableString =
			"""
			CREATE VIRTUAL TABLE \(DSFFullTextSearchIndex.TableDef)
			USING FTS5(url UNINDEXED, content);
			"""

		var createTableStatement: OpaquePointer?
		defer {
			sqlite3_finalize(createTableStatement)
		}

		guard sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			Swift.print("failure creating table prepare: \(errmsg)")
			return .sqliteUnableToPrepare
		}

		guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
			let errmsg = String(cString: sqlite3_errmsg(self.db)!)
			Swift.print("failure creating table: \(errmsg)")
			return .sqliteUnableToStep
		}

		return .success
	}
}
