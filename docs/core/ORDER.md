# Order and visibility decisions

This file is the truth table for the kernel. A case that is not here is not implemented;
stop and ask Fady.

## Notation

- `A`, `B`, `C`, `D` are inserted code points.
- `D(B)` means `D` is inserted with `B` as its left origin.
- `del(B)` means a delete targeting `B`.
- `B < C` means `B`'s NodeID sorts before `C`'s under the R1 order.
- **Concurrent** means the ops were produced without seeing each other.

## 1. NodeID total order

TBD. Define, in this order:

1. How two replica UUIDs compare: lexicographic by code point, byte order, case-folded, or
   something else?
2. How counters compare.
3. Where the virtual root sits. It anchors the first insert; it must not behave like a
   normal sibling.
4. What happens on equal `(replica, counter)` values. If that is impossible, say why and
   assert it at the boundary.

## 2. Insert placement

TBD. Given an insert with a known `leftOrigin` and existing children of that origin, decide:

1. Does the new node become a child of the left origin, or is it inserted among the
   origin's existing siblings?
2. How does the NodeID order decide the placement?
3. What happens when the left origin is a tombstone?
4. What happens when the left origin is the root?

## 3. Sibling order and traversal

TBD. Decide:

1. Sibling direction: ascending or descending NodeID.
2. Traversal: is a node's subtree rendered before its next sibling (depth-first), or are
   all direct children rendered before any descendants?
3. Does render recurse into a tombstone's children? Where do they appear?
4. What keeps concurrent same-origin runs contiguous (CR-05)?

## 4. The decision table

Every row must be filled before the corresponding kernel code is written. `Decision` is the
exact rule, not a description of the code. `Golden` points to the hand-computed fixture.
`Status` is `open` or `decided`.

| # | History | Question | Decision | Golden | Status |
| --- | --- | --- | --- | --- | --- |
| O-01 | `A` after root | Does `A` render? | TBD | G01 | open |
| O-02 | `B` after `A` | Does it render `AB`? | TBD | G02 | open |
| O-03 | `B` and `C` after root, concurrent | `BC` or `CB`? | TBD | G03 | open |
| O-04 | `D` after `B`, with `B` and `C` siblings | `BDC` or `BCD`? | TBD | G04 | open |
| O-05 | `del(B)`, with `A` and `C` live | Does it render `AC`? | TBD | G05 | open |
| O-06 | `del(B)`, with `D` a child of `B` | Where does `D` render? | TBD | G06 | open |
| O-07 | `D` after tombstone `B` | Where does `D` render? | TBD | G07 | open |
| O-08 | Duplicate insert delivery | Is it a no-op? | TBD | G08 | open |
| O-09 | Delete arrives before its insert | Is it buffered, then applied? | TBD | G09 | open |
| O-10 | Same replica, counter gap | Order by counter, not density? | TBD | G10 | open |
| O-11 | Three concurrent runs at one origin | Are the blocks contiguous? | TBD | G11 | open |
| O-12 | Nested concurrent runs | Is it `A C B D`, or another order? | TBD | G12 | open |

## 5. Change rule

A decision may be changed only with:

- a dated entry in this table;
- a new or updated golden;
- a note in the PR explaining the change and the invariant it protects.

A new ADR is required if the change alters a PRD invariant or the public wire format.
Silent changes are forbidden.
