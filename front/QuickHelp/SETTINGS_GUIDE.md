# Settings Screen Guide

## Overview
The Settings screen provides a clean, minimal interface for essential user preferences and account management. It focuses on the most important features: theme selection and account deletion.

## Features

### 1. Theme Selection
- **Location**: Settings → Внешний вид
- **Functionality**: Opens ThemeSelectorView in a sheet
- **Display**: Shows current theme name
- **Icon**: Paintbrush icon
- **Style**: Clean button with chevron indicator

### 2. Account Deletion
- **Location**: Settings → Аккаунт
- **Functionality**: Deletes user account and all associated data
- **Confirmation**: Shows alert with warning message
- **Icon**: Trash icon (red)
- **API Endpoint**: `DELETE /user/{userId}/delete`
- **Style**: Red button to indicate destructive action

## Navigation

### Access
- **Button**: Gear icon in navigation bar (HomeView only)
- **Presentation**: Modal sheet
- **Dismiss**: "Готово" button or swipe down

### Integration
- **MainTabView**: Contains the settings button and sheet presentation
- **ChatService**: Passed to SettingsView for account deletion functionality
- **ThemeManager**: Used for theme selection

## UI/UX Design

### Layout
- **Structure**: Simple list with two sections
- **Sections**: Внешний вид, Аккаунт
- **Style**: Native iOS settings style with minimal design

### Visual Design
- **Icons**: SF Symbols for each section
- **Colors**: Uses custom theme colors
- **Typography**: Consistent with app design
- **Spacing**: Clean, adequate spacing

### Minimalist Approach
- **Focused Content**: Only essential features
- **Clean Interface**: No unnecessary information
- **Clear Actions**: Obvious purpose for each option
- **Consistent Styling**: Unified design language

## Code Structure

### SettingsView.swift
```swift
struct SettingsView: View {
    @ObservedObject var chatService: ChatService
    @ObservedObject private var themeManager = ThemeManager.shared
    // ... state variables and body
}
```

### Key Methods
- `deleteAccount()`: Handles account deletion API call
- Sheet presentation for theme selector
- Alert presentation for delete confirmation

## Benefits

### User Experience
1. **Focused Interface**: Only essential settings
2. **Quick Access**: Easy to find and use
3. **Standard iOS Pattern**: Familiar settings interface
4. **Clean Design**: No visual clutter

### Code Organization
1. **Simplified Logic**: Less complexity
2. **Maintainability**: Easier to modify
3. **Performance**: Faster loading
4. **Clean Architecture**: Follows iOS design patterns

## Design Principles

### Minimalism
- **Essential Only**: Include only necessary features
- **Clear Purpose**: Each option has obvious function
- **Reduced Cognitive Load**: Less decision making required

### Consistency
- **Visual Harmony**: Unified design language
- **Interaction Patterns**: Standard iOS behaviors
- **Color Usage**: Consistent with app theme

### Accessibility
- **Clear Labels**: Descriptive text for each option
- **Adequate Touch Targets**: Proper button sizes
- **Semantic Icons**: Meaningful visual indicators

## Future Considerations

### Potential Additions (If Needed)
1. **Language Settings**: If multi-language support becomes essential
2. **Notification Preferences**: If push notifications are added
3. **Privacy Controls**: If data privacy features are needed
4. **Export Options**: If data export becomes important

### Technical Improvements
1. **Settings Persistence**: Save theme preferences
2. **Settings Validation**: Validate settings before saving
3. **Error Handling**: Better error messages for failures

## Testing Considerations

### Manual Testing
1. **Theme Selection**: Verify theme changes apply correctly
2. **Account Deletion**: Test deletion flow and data clearing
3. **Navigation**: Test sheet presentation and dismissal
4. **Accessibility**: Test with VoiceOver

### Unit Testing
1. **Settings Logic**: Test settings validation
2. **API Integration**: Test account deletion API calls
3. **State Management**: Test settings state changes

## Security Considerations

### Account Deletion
1. **Confirmation Required**: User must confirm deletion
2. **Data Clearing**: All local data is cleared
3. **API Security**: Proper authentication for deletion endpoint
4. **Error Handling**: Graceful handling of deletion failures

### Data Protection
1. **No Sensitive Data Display**: Settings don't show sensitive information
2. **Secure Storage**: Settings stored securely
3. **Privacy Compliance**: Follows privacy guidelines 