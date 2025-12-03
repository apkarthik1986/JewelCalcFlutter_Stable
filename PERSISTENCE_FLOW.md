# Data Persistence Flow Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Jewel Calc App                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐         ┌──────────────┐                      │
│  │   UI Layer   │◄────────┤  State Layer │                      │
│  │  (Widgets)   │────────►│  (Variables) │                      │
│  └──────────────┘         └──────┬───────┘                      │
│                                   │                               │
│                                   │ Debounced (500ms)            │
│                                   │ or Immediate                  │
│                                   ▼                               │
│                          ┌────────────────┐                      │
│                          │  Save Logic    │                      │
│                          │ _saveFormState │                      │
│                          └────────┬───────┘                      │
│                                   │                               │
│                                   ▼                               │
│                          ┌────────────────┐                      │
│                          │SharedPreferences│                     │
│                          │  (Local Store) │                      │
│                          └────────────────┘                      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow: User Input → Storage

### 1. Text Field Input (Customer Information)

```
User Types in Text Field
         │
         ▼
TextEditingController Notifies Listener
         │
         ▼
_debouncedSaveFormState() Called
         │
         ▼
Cancel Existing Timer (if any)
         │
         ▼
Start New Timer (500ms)
         │
         ▼
[User stops typing for 500ms]
         │
         ▼
Timer Fires
         │
         ▼
_saveFormState() Called
         │
         ▼
Data Saved to SharedPreferences
```

### 2. Dropdown/Button Selection

```
User Selects Option
         │
         ▼
onChanged/onSelectionChanged Handler
         │
         ▼
setState() Updates UI
         │
         ▼
_debouncedSaveFormState() Called
         │
         ▼
[Same flow as text field]
```

### 3. Add Item Action

```
User Clicks "Add Item" Button
         │
         ▼
_addCurrentItem() Method
         │
         ▼
Item Added to items List
         │
         ▼
setState() Updates UI
         │
         ▼
unawaited(_saveFormState())
         │
         ▼
Data Saved Immediately (Fire-and-Forget)
```

## Data Flow: Storage → UI

### App Startup

```
App Launches
         │
         ▼
initState() Called
         │
         ▼
_loadBaseValues() Called
         │
         ▼
Load Base Values from SharedPreferences
         │
         ▼
setState() Updates Base Values UI
         │
         ▼
_loadFormState() Called
         │
         ▼
Load All Form Data from SharedPreferences
         │
         ├─────────► Customer Information
         ├─────────► Items List (Deserialize)
         ├─────────► Exchange Items (Deserialize)
         ├─────────► Current Input State
         ├─────────► Discount Settings
         └─────────► Exchange Input State
         │
         ▼
setState() Updates Form UI
         │
         ▼
App Ready with Restored Data
```

## Persistence Lifecycle

```
┌───────────────────────────────────────────────────────────┐
│                    Day 1 (Monday)                          │
├───────────────────────────────────────────────────────────┤
│ 09:00 AM │ User opens app                                 │
│          │ - All data: Empty (first use)                 │
├──────────┼───────────────────────────────────────────────┤
│ 09:05 AM │ User sets gold rate: 6000                     │
│          │ - Saved to SharedPreferences                  │
├──────────┼───────────────────────────────────────────────┤
│ 09:10 AM │ User enters customer "John Doe"               │
│          │ - Auto-saved after 500ms                       │
├──────────┼───────────────────────────────────────────────┤
│ 09:15 AM │ User adds 3 items                             │
│          │ - Each item saved immediately                  │
├──────────┼───────────────────────────────────────────────┤
│ 09:20 AM │ User closes app                               │
│          │ - All data persisted                          │
├──────────┼───────────────────────────────────────────────┤
│ 02:00 PM │ User reopens app                              │
│          │ - Gold rate: 6000 (restored)                  │
│          │ - Customer: "John Doe" (restored)             │
│          │ - Items: All 3 items (restored)               │
├──────────┼───────────────────────────────────────────────┤
│ 05:00 PM │ User closes app for the day                   │
│          │ - All data persisted                          │
└──────────┴───────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────┐
│                    Day 2 (Tuesday)                         │
├───────────────────────────────────────────────────────────┤
│ 09:00 AM │ User opens app                                 │
│          │ - Gold rate: 6000 (PERSISTED from yesterday) │
│          │ - Customer: "John Doe" (PERSISTED)            │
│          │ - Items: All 3 items (PERSISTED)              │
├──────────┼───────────────────────────────────────────────┤
│ 09:05 AM │ User updates gold rate: 6100                  │
│          │ - Saved to SharedPreferences                  │
├──────────┼───────────────────────────────────────────────┤
│ 09:10 AM │ User adds 2 more items (continues work)       │
│          │ - Now has 5 items total                        │
│          │ - All saved                                    │
└──────────┴───────────────────────────────────────────────┘
```

## Data Categories and Their Behavior

```
┌─────────────────┬──────────────────┬──────────────────────┐
│   Data Type     │  Reset Trigger   │   Persistence Scope  │
├─────────────────┼──────────────────┼──────────────────────┤
│ Metal Rates     │ Manual reset     │ Indefinite           │
│ Wastage %       │ Manual reset     │ Indefinite           │
│ Making Charges  │ Manual reset     │ Indefinite           │
│ Customer Info   │ Manual reset     │ Indefinite           │
│ Items List      │ Manual reset     │ Indefinite           │
│ Exchange Items  │ Manual reset     │ Indefinite           │
│ Current Input   │ Manual reset     │ Indefinite           │
│ Discount State  │ Manual reset     │ Indefinite           │
└─────────────────┴──────────────────┴──────────────────────┘

Note: All data persists indefinitely. Base values can be reset 
via "Reset to Defaults" in Settings. Form data can be reset via 
"Reset All" button on main screen.
```

## Storage Keys

All data is stored in SharedPreferences with the following keys:

### Base Values
```
rate_gold_22k         → 6000.0
rate_gold_20k         → 5500.0
rate_gold_18k         → 5000.0
rate_silver           → 196.0
gold_wastage          → 10.0
silver_wastage        → 8.0
gold_mc               → 350.0
silver_mc             → 200.0
```
Note: "last_date" key is no longer used as base values persist indefinitely.

### Form Data
```
form_bill_number      → "INV-001"
form_customer_acc     → "ACC123"
form_customer_name    → "John Doe"
form_address          → "123 Main St"
form_mobile           → "1234567890"
form_selected_type    → "Gold 22K/916"
form_weight           → 10.0
form_wastage          → 1.0
form_making_charges   → 350.0
form_mc_type          → "Rupees"
form_mc_percentage    → 0.0
form_discount_type    → "Percentage"
form_discount_amount  → 0.0
form_discount_percentage → 5.0
form_exchange_type    → "Gold 22K/916"
form_exchange_weight  → 5.0
form_exchange_wastage → 0.0
form_items            → ["Gold 22K/916|10.0|1.0|6000.0|350.0", ...]
form_exchange_items   → ["Silver|100.0|30.0|196.0", ...]
```

## Performance Characteristics

### Write Operations
- **Text fields:** Debounced 500ms (reduced from potentially hundreds per second to ~2 per second)
- **Buttons/Dropdowns:** Immediate (negligible impact)
- **Add/Remove items:** Immediate (user-initiated, infrequent)

### Read Operations
- **App start:** One read operation per key (~20 keys total)
- **During use:** No reads (all in memory)

### Memory Usage
- **Timer:** ~8 bytes (one Timer? reference)
- **Listeners:** ~40 bytes (5 listener references)
- **Total overhead:** <100 bytes

### Storage Size
- **Base values:** ~72 bytes (9 doubles)
- **Form strings:** ~200-1000 bytes (variable based on input)
- **Items list:** ~50 bytes per item
- **Total:** Typically <5 KB for normal usage

## Error Handling

```
┌─────────────────────────────┐
│  SharedPreferences Read     │
└──────────┬──────────────────┘
           │
           ▼
    ┌──────────────┐
    │ Key exists?  │
    └──┬────────┬──┘
       │        │
      Yes      No
       │        │
       ▼        ▼
   ┌────┐   ┌─────────┐
   │Use │   │Use      │
   │Value│  │Default  │
   └────┘   └─────────┘
       │        │
       └────┬───┘
            ▼
     ┌──────────────┐
     │ Parse value  │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ Valid data?  │
     └──┬────────┬──┘
        │        │
       Yes      No
        │        │
        ▼        ▼
    ┌────┐   ┌──────────┐
    │Use │   │Use       │
    │Data│   │Default   │
    └────┘   │or Ignore │
             └──────────┘
```

## Thread Safety

Flutter's SharedPreferences is thread-safe by default:
- All operations are atomic
- Writes are queued and executed in order
- No risk of data corruption from concurrent access

## Limitations

1. **Storage Limit:** SharedPreferences has no hard limit but should be used for small data
   - Our usage: <10 KB typical, <50 KB maximum
   - Well within acceptable range

2. **Platform Limitations:**
   - Android: Deleted on app uninstall
   - iOS: Deleted on app uninstall
   - No cross-device sync

3. **No Encryption:**
   - Data stored in plain text
   - Accessible if device is rooted/jailbroken
   - Not suitable for sensitive data (but we only store invoice data)

## Future Enhancements

Possible improvements:
1. **Cloud Backup:** Firebase/AWS integration for uninstall persistence
2. **Encryption:** Add encryption for sensitive customer data
3. **Compression:** Compress items list if it grows large
4. **Versioning:** Add version field for migration compatibility
5. **Export/Import:** CSV or JSON export for backup
