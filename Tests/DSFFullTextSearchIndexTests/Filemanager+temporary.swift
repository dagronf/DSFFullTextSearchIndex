//
//  FileManager+temporary.swift
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

public extension FileManager {
	/// Create a new uniquely-named temporary folder.
	/// - Parameter prefix: (optional) prefix to add the temporary file name
	/// - Parameter fileExtension: (optional) file extension (without the `.`) to use for the created file
	/// - Parameter contents: (optional) the data to write to the file
	func createTemporaryFile(prefix: String? = nil, fileExtension: String? = nil, contents: Data? = nil) throws -> URL {

		var tempFilename = NSTemporaryDirectory()

		if let prefix = prefix {
			tempFilename += prefix + "_"
		}

		tempFilename += ProcessInfo.processInfo.globallyUniqueString

		if let fileExtension = fileExtension {
			tempFilename += "." + fileExtension
		}

		let tempURL = URL(fileURLWithPath: tempFilename)

		if let c = contents {
			try c.write(to: tempURL, options: .atomicWrite)
		}

		return tempURL
	}

	/// Create a new uniquely-named folder within this folder.
	/// - Parameter prefix: (optional) prefix to add the temporary folder name
	/// - Parameter shouldCreate: (optional) should the folder be created (defaults to true)
	func createTemporaryFolder(prefix: String? = nil, shouldCreate: Bool = true) throws -> URL {
		var tempFolderName = NSTemporaryDirectory()
		if let prefix = prefix {
			tempFolderName += prefix + "_"
		}

		tempFolderName += ProcessInfo.processInfo.globallyUniqueString
		
		let tempURL = URL(fileURLWithPath: tempFolderName)

		if shouldCreate {
			try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true, attributes: nil)
		}
		return tempURL
	}
}


@objc public class DSFTemporaryFile: NSObject {
	private let fileManager: FileManager
	@objc public let tempFile: URL

	public override init() {
		self.fileManager = FileManager.default
		guard let file = try? self.fileManager.createTemporaryFile() else {
			assert(false)
		}
		self.tempFile = file
		super.init()
	}
	@objc public init(_ filemanager: FileManager = FileManager.default) throws {
		self.fileManager = filemanager
		self.tempFile = try filemanager.createTemporaryFile()
		super.init()
	}
	deinit {
		try? self.fileManager.removeItem(at: self.tempFile)
	}
}
