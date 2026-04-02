1. **Remove unsafe force unwrap in `ScoresheetEntryView.swift`**:
    - The `ScoresheetEntryView` uses `importDraftForReview!` in the `reviewSheetPresented` getter and `sheet` presenter. Refactor this to use optional binding or direct unwrap if guaranteed by the context. Wait, the `get: { importDraftForReview! }` is dangerous, even if the sheet is only presented when `importDraftForReview != nil`, it's better to construct the binding cleanly, or use `sheet(item:)`. Currently `importDraftForReview` is an optional state, and it uses `sheet(isPresented:)`. I'll refactor `sheet(isPresented: reviewSheetPresented)` to `sheet(item: $importDraftForReview)`. This removes the need for `reviewSheetPresented` and the `!` force-unwrap.

2. **Replace redundant `DateFormatter` inline allocation in `ScoresheetEntryView.swift`**:
    - `importedAt.formatted(date: .abbreviated, time: .shortened)` uses `.formatted()` which allocates a formatter under the hood, and we have a rule "Expensive objects like `DateFormatter`... must be cached ... Avoid calling `.formatted()` inline on primitive types or dates inside SwiftUI View properties or loops". I will replace it with `importedAt.abbreviatedDateTimeFormatted`.

3. **Simplify `DispatchQueue.main.async` in SwiftUI View**:
    - `ScoresheetEntryView` uses `DispatchQueue.main.async` for updating state when handling callbacks (`onScan` and `onPDF` from `ScoresheetImportSourceChooserView`). This can be improved or removed depending on how SwiftUI handles it, or use `Task { @MainActor in }` for modern concurrency. However, replacing it with `Task { @MainActor in }` is cleaner and adopts Swift Concurrency as recommended.

4. **Complete Pre-commit steps**:
    - Ensure proper testing, verifications, reviews and reflections are done.
