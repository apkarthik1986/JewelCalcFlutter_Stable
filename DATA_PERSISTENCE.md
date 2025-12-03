# Data Persistence Implementation

## Overview

The Jewel Calc application implements comprehensive data persistence to ensure all user-entered data is preserved across app sessions, restarts, and throughout daily usage.

## Implementation Details

### Storage Mechanism

The application uses `SharedPreferences` for local data storage, which provides:
- ✅ **Persistence across app restarts**: Data survives when the app is closed and reopened
- ✅ **Persistence across device reboots**: Data survives system restarts
- ✅ **Fast read/write operations**: Efficient local storage
- ❌ **Does NOT persist after app uninstall**: Data is lost when the app is uninstalled

### What Data Persists

#### Base Values (Reset Daily at Midnight)
These values are intended for daily configuration and automatically reset to zero at midnight:
- Metal rates per gram (Gold 22K/916, Gold 20K/833, Gold 18K/750, Silver)
- Gold wastage percentage
- Silver wastage percentage
- Gold making charge per gram
- Silver making charge per gram

#### Form Data (Persists Indefinitely)
These values persist across all app sessions until manually cleared by the user:
- Bill number
- Customer account number
- Customer name
- Address
- Mobile number
- Added items list (with all item details)
- Exchange items list (with all exchange details)
- Current item input state (selected type, weight, wastage, making charges)
- Making charge type (Rupees vs Percentage)
- Discount settings (type, amount, percentage)
- Exchange input state (type, weight, wastage deduction)

### Auto-Save Mechanism

#### Debounced Text Field Auto-Save
To provide a seamless user experience without excessive storage operations:
- Customer information fields (bill number, customer account, name, address, mobile) auto-save 500ms after the user stops typing
- This prevents a save operation on every keystroke
- Uses a Timer that is cancelled and reset with each keystroke

#### Immediate Save Operations
The following actions trigger immediate save:
- Adding an item to the list
- Removing an item from the list
- Adding an exchange item to the list
- Removing an exchange item from the list
- Changing dropdown selections (metal type, making charge type, discount type)
- Changing numeric values (weight, wastage, making charges, discount)

#### Manual Save Operations
- Generating a PDF invoice triggers a save to ensure data is persisted before printing
- Saving base values in the settings dialog

### Code Implementation

#### Key Methods

**_saveFormState()**
```dart
Future<void> _saveFormState() async
```
Saves all form data to SharedPreferences, including:
- Customer information
- Current item input state
- Discount settings
- Exchange input state
- Items list (serialized)
- Exchange items list (serialized)

**_loadFormState()**
```dart
Future<void> _loadFormState() async
```
Loads all form data from SharedPreferences and updates the UI state.

**_debouncedSaveFormState()**
```dart
void _debouncedSaveFormState()
```
Implements debounced saving with a 500ms delay to avoid excessive writes during typing.

**_clearFormState()**
```dart
Future<void> _clearFormState() async
```
Removes all form data from SharedPreferences. Called only when the user explicitly taps the Reset button.

#### Data Serialization

**JewelItem** and **ExchangeItem** classes implement serialization:
```dart
String toStorageString()  // Converts object to pipe-delimited string
static fromStorageString(String str)  // Parses string back to object
```

This allows complex objects to be stored in SharedPreferences as String lists.

## User Experience

### Normal Usage Flow
1. User opens app for the first time → Empty state
2. User enters customer information → Auto-saves after 500ms
3. User adds items → Each item saves immediately
4. User closes app → All data preserved
5. User reopens app next day → Form data restored, base values reset to 0
6. User updates base values in settings → Base values saved for the day
7. User continues working → All changes persist automatically

### Reset Functionality
The Reset All button (refresh icon) clears:
- All customer information
- All items
- All exchange items
- Current input state
- Discount settings
- Persisted form state in storage

Base values are NOT cleared by the reset button - they persist for the day and reset at midnight.

### Settings Configuration
The Settings dialog allows configuration of:
- Metal rates
- Wastage percentages
- Making charges

These values persist throughout the day and automatically reset at midnight for fresh daily configuration.

## Technical Considerations

### Performance
- Debounced saves (500ms) prevent excessive storage operations
- Fire-and-forget pattern using `unawaited()` for non-critical saves
- Read operations only on app start
- No background sync or polling

### Memory Management
- Timer properly cancelled in dispose()
- Controllers disposed properly
- No memory leaks from listeners

### Error Handling
- Uses default values if SharedPreferences keys don't exist
- Validates deserialized data before using it
- Gracefully handles corrupt or invalid stored data

## Limitations and Future Enhancements

### Current Limitations
1. **No cloud backup**: Data is stored only on the device
2. **No uninstall persistence**: Data is lost if app is uninstalled
3. **No multi-device sync**: Each device has its own local data
4. **No data export**: No built-in way to export/import data

### Possible Future Enhancements
To enable persistence after uninstall and multi-device sync:
1. Add Firebase integration for cloud storage
2. Implement user authentication
3. Add data export/import functionality (CSV, JSON)
4. Add backup/restore features
5. Implement cloud sync with conflict resolution

These enhancements would require:
- Network connectivity
- User accounts and authentication
- Privacy considerations and data handling policies
- Significant architectural changes
- Additional dependencies and complexity

## Testing

To verify persistence is working correctly:
1. Enter customer information and close the app → Data should be present on reopen
2. Add multiple items and close the app → All items should be present on reopen
3. Set discount values and close the app → Discount settings should be restored
4. Add exchange items and close the app → Exchange items should be present
5. Test across midnight boundary → Base values should reset, form data should remain
6. Test Reset button → All form data should be cleared
7. Test base value settings → Values should persist throughout the day

## Conclusion

The current implementation provides robust local data persistence that meets the requirement of preserving data "throughout the app" usage. The limitation of not persisting after uninstall is inherent to the use of SharedPreferences and is acknowledged in the requirements as "if possible" - implementing this would require cloud infrastructure which is beyond the scope of local-only storage.
