# DSFFullTextSearchIndex

A full text search class using sqlite FTS5 as the text indexer

``` swift
@objc public class DSFFullTextSearchIndex: NSObject
```

## Inheritance

`NSObject`

## Methods

## add(document:useNativeEnumerator:stopWords:)

``` swift
@objc public func add(document: Document, useNativeEnumerator: Bool = false, stopWords: Set<String>? = nil) -> Status
```

## add(url:text:canReplace:useNativeEnumerator:stopWords:)

Add a new document to the search index

``` swift
@objc public func add(url: URL, text: String, canReplace: Bool = true, useNativeEnumerator: Bool = false, stopWords: Set<String>? = nil) -> Status
```

### Parameters

  - url: The unique URL identifying the document
  - text: The document text
  - canReplace: Allow or disallow replacing a document with an identical URL
  - useNativeEnumerator: If true, uses the native text enumerator methods to split into words before adding to index.  Can improve word searching for CJK texts
  - stopWords: If set, removes any words in the set from the document before adding to the index

### Returns

true if the document was successfully added to the index, false otherwise

## add(documents:canReplace:useNativeEnumerator:stopWords:)

``` swift
@objc public func add(documents: [Document], canReplace _: Bool = true, useNativeEnumerator: Bool = false, stopWords: Set<String>? = nil) -> Status
```

## inTransaction(block:)

Run the provided block within a search index transaction.

``` swift
@objc public func inTransaction(block: () -> Status) -> Status
```

## remove(url:)

Remove the specified document from the search index

``` swift
@objc public func remove(url: URL) -> Status
```

## remove(urls:)

Remove the specified documents from the search index

``` swift
@objc public func remove(urls: [URL]) -> Status
```

## removeAll()

Remove all documents in the search index

``` swift
@objc public func removeAll() -> Status
```

## exists(url:)

Returns true if the specified document url exists in the search index, false otherwise

``` swift
@objc public func exists(url: URL) -> Bool
```

## allURLs()

Returns all the document URLs stored in the index

``` swift
@objc public func allURLs() -> [URL]
```

## count()

Returns the number of documents in the search index

``` swift
@objc public func count() -> Int32
```

## search(text:)

Perform a text search using the current index

``` swift
@objc public func search(text: String) -> [URL]?
```

### Parameters

  - text: The text to search for

### Returns

An array of document URLs matching the text query
