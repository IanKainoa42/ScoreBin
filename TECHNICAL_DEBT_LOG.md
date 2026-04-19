
## Fix: Silently swallowed `modelContext.save()` errors

### Description
Added error handling to UI views where `try modelContext.save()` was failing silently. Caught errors are now assigned to a `@State private var saveError: String?` which triggers an `.alert` explaining the failure.

### Before
```swift
do {
    try modelContext.save()
} catch {
    print("Failed to save: \(error)")
}
dismiss()
```

### After
```swift
@State private var saveError: String?

// ...

do {
    try modelContext.save()
    dismiss()
} catch {
    saveError = error.localizedDescription
    print("Failed to save: \(error)")
}

// In the view body:
.alert(
    "Error Saving",
    isPresented: Binding(
        get: { saveError != nil },
        set: { if !$0 { saveError = nil } }
    )
) {
    Button("OK", role: .cancel) { saveError = nil }
} message: {
    if let saveError {
        Text(saveError)
    }
}
```

### Performance Metrics
No direct impact on speed, but improves user trust and prevents data loss going unnoticed.

### Risk Assessment
Very low risk. The code maintains the exact same model behavior while exposing previously swallowed exceptions to the user.
