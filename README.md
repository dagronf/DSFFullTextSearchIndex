# DSFFullTextSearchIndex

A simple iOS/macOS/tvOS full text search (FTS) class using SQLite FTS5 using a similar API as SKSearchKit with no external dependencides

<p align="center">
    <img src="https://img.shields.io/github/v/tag/dagronf/DSFFullTextSearchIndex" />
    <img src="https://img.shields.io/badge/macOS-10.11+-red" />
    <img src="https://img.shields.io/badge/iOS-11.0+-blue" />
    <img src="https://img.shields.io/badge/tvOS-11.0+-orange" />
    <img src="https://img.shields.io/badge/macCatalyst-1.0+-yellow" />
</p>

<p align="center">
    <img src="https://img.shields.io/badge/Swift-5.0-orange.svg" />
    <img src="https://img.shields.io/badge/License-MIT-lightgrey" />
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
</p>

## Why

I wanted to add a full text search index to my macOS/iOS application and realized that SKSearchKit (and thus [DFSearchKit](https://github.com/dagronf/DFSearchKit) is macOS only. 

SQLite has solid FTS capabilities via and I wanted to be able to use these in a similar way as SKSearchKit.  I also wanted a simple wrapper that **didn't have any dependencies**.  As much as I love [GRDB](https://github.com/groue/GRDB.swift) I certainly didn't need everything that it provides.

I also wanted something that can both :-

* work independently in an app that doesn't have a traditional database, and
* work in an app with an existing SQLite database.
* be able to be shared between applications on iOS, macOS, macOS (Catalyst) and tvOS.

## Simple example

```swift

// Create an index

let index = DSFFullTextSearchIndex()
index.create(filePath: /* some file path */)

//
// Add some documents
//
let url1 = URL(string: "demo://maintext/1")
index.add(url: url1, text: "Sphinx of black quartz judge my vow")

let url2 = URL(string: "demo://maintext/2")
index.add(url: url2, text: "Quick brown fox jumps over the lazy dog")

let url3 = URL(string: "demo://maintext/3")
index.add(url: url3, text: "The dog didn't like the bird sitting on the fence and left quietly")

//
// Search
//
let urls1 = index.search(text: "quartz")   // single match - url1
let urls2 = index.search(text: "quick")    // single match - url2
let urls3 = index.search(text: "dog")      // two matches - url1 and url3

// Search with a wildcard
let urls4 = index.search(text: "qu*")       // three matches = url1 (quartz), url2 (quick) and url3 (quietly)

```

## API documentation

- [DSFFullTextSearchIndex](DSFFullTextSearchIndex.md)

Generated using [swift-doc](https://github.com/SwiftDocOrg/swift-doc).


## To do

* Add a custom tokenizer to more accurately handle stop words and CJK
* Character folding etc.
* A ton of more stuff too.

## License

```
MIT License

Copyright (c) 2020 Darren Ford

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
