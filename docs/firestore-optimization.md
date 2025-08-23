# Firestore Query Optimization Guide

This guide lists practical techniques to reduce reads, latency, and cost in Cloud Firestore.

## 1) Model data for queries (not for writes)
- Prefer flatter, queryable shapes over deeply nested subcollections when you need list views.
- Denormalize selectively to avoid N+1 reads (duplicate small, seldom-changing fields).

```text
users/{userId}
chats/{chatId}
chats/{chatId}/messages/{messageId}
chatSummaries/{chatId}  // denormalized: lastMessage, participants, updatedAt
```

## 2) Create composite indexes proactively
- Firestore requires composite indexes for multiple where+orderBy combinations.
- Use the error link from the SDK to auto-create required indexes.

```bash
# Example: status + updatedAt descending
# Go to the generated link or create via console
```

## 3) Use collectionGroup for cross-collection queries
- Replace N queries across subcollections with one `collectionGroup` query.

```js
// Get all comments across posts
const q = query(
  collectionGroup(db, 'comments'),
  where('authorId', '==', userId),
  orderBy('createdAt', 'desc'),
  limit(50)
);
```

## 4) Use cursors instead of offsets
- `startAfter`, `startAt`, `endBefore`, `endAt` scale better than `offset`.

```js
const first = await getDocs(query(ref, orderBy('createdAt'), limit(20)));
const next = await getDocs(query(ref, orderBy('createdAt'), startAfter(lastDoc), limit(20)));
```

## 5) Avoid `in`/`array-contains-any` with very large sets
- Break large sets into smaller batches or precompute reverse indexes.

```js
// Reverse index: tag -> postIds
const q = query(collection(db, 'tagPosts'), where('tag', '==', 'swift'), limit(50));
```

## 6) Filter first, then orderBy on the same field set
- Always have an index that matches your `where` and `orderBy` chain.

```js
// Good: where(status) then orderBy(updatedAt) with composite index
query(tasksRef, where('status', '==', 'open'), orderBy('updatedAt', 'desc'), limit(25));
```

## 7) Restrict document size and hot fields
- Keep total document size < 1 MB.
- Avoid frequently mutating large arrays; use counters or subcollections instead.

## 8) Cache aggressively on client
- Enable persistence; use `getDocFromCache` where acceptable.

```js
// Web v9
import { initializeFirestore, persistentLocalCache } from 'firebase/firestore';
const db = initializeFirestore(app, { localCache: persistentLocalCache() });
```

## 9) Use server timestamps and monotonic keys
- `serverTimestamp()` for ordering; shard counters for hotspots.

## 10) Measure with profiling tools
- Use Firebase Performance Monitoring, Cloud Trace, and emulator suite.

### Example: Efficient feed query
```js
const q = query(
  collection(db, 'feedItems'),
  where('audience', 'array-contains', userId),
  orderBy('publishedAt', 'desc'),
  limit(30)
);
```

### Security rules matter
- Rules cannot reduce billed reads; design queries to be selective first, then write rules to enforce access.
