---
name: iOS Workout Tracker
overview: Build a SwiftUI iOS app for Heavy Duty HIT training with local persistence, featuring workout A/B routines, progress logging, and simple scheduling.
todos:
  - id: xcode-project
    content: Create Xcode project with SwiftUI lifecycle and SwiftData
    status: completed
  - id: data-models
    content: Define SwiftData models (Exercise, WorkoutLog, ContentNote)
    status: completed
  - id: theme
    content: Create dark theme and design system (colors, typography)
    status: completed
  - id: home-view
    content: Build HomeView with next workout indicator and A/B cards
    status: completed
  - id: workout-detail
    content: Build WorkoutDetailView showing exercises and goals
    status: completed
  - id: log-sheet
    content: Create LogWorkoutSheet for recording actual performance
    status: completed
  - id: history-view
    content: Implement HistoryView with workout logs
    status: completed
  - id: notes-view
    content: Add NotesView for informative content and links
    status: completed
  - id: seed-data
    content: Seed initial A/B workout exercises
    status: completed
isProject: false
---

# iOS Workout Tracker App

## Architecture

```mermaid
graph TB
    subgraph views [Views Layer]
        HomeView
        WorkoutDetailView
        LogWorkoutSheet
        HistoryView
        NotesView
    end
    
    subgraph viewmodels [ViewModels]
        WorkoutViewModel
        HistoryViewModel
    end
    
    subgraph data [Data Layer]
        SwiftData[(SwiftData)]
    end
    
    HomeView --> WorkoutViewModel
    WorkoutDetailView --> WorkoutViewModel
    HistoryView --> HistoryViewModel
    WorkoutViewModel --> SwiftData
    HistoryViewModel --> SwiftData
```



## Data Models (SwiftData)

- **WorkoutType**: Enum (A, B) defining the two workout days
- **Exercise**: Name, target weight, target reps, notes, linked to workout type
- **WorkoutLog**: Date, exercise reference, actual weight, actual reps, feeling (1-5 scale), notes
- **ContentNote**: Title, body text, optional URL links

## Screens

1. **Home** - Next scheduled workout, days since last workout, quick access to A/B
2. **Workout Detail** - List exercises for A or B, show goals, button to log
3. **Log Workout Sheet** - Record actual weight/reps, feeling slider, notes
4. **History** - Calendar or list view of past workouts with progress indicators
5. **Notes** - Informative content, links to videos/posts

## Project Structure

```
WorkoutTracker/
├── WorkoutTrackerApp.swift
├── Models/
│   ├── WorkoutType.swift
│   ├── Exercise.swift
│   ├── WorkoutLog.swift
│   └── ContentNote.swift
├── ViewModels/
│   ├── WorkoutViewModel.swift
│   └── HistoryViewModel.swift
├── Views/
│   ├── HomeView.swift
│   ├── WorkoutDetailView.swift
│   ├── LogWorkoutSheet.swift
│   ├── HistoryView.swift
│   ├── NotesView.swift
│   └── Components/
│       ├── ExerciseRow.swift
│       └── WorkoutCard.swift
├── Theme/
│   └── AppTheme.swift
└── Preview Content/
    └── SampleData.swift
```

## Design System

- **Colors**: Dark background (#121212), accent color for CTAs, muted grays for secondary text
- **Typography**: SF Pro with clear hierarchy (title, body, caption)
- **Components**: Cards with subtle borders, minimal shadows, consistent spacing

## Implementation Order

1. Create Xcode project with SwiftUI + SwiftData
2. Define data models
3. Build theme/design system
4. Create Home view with workout cards
5. Build Workout Detail view with exercise list
6. Add Log Workout sheet with form
7. Implement History view
8. Add Notes section
9. Seed initial A/B workout data

## Initial Workout Data (Mentzer-style)

**Workout A:**

- Squats
- Calf Raises

**Workout B:**

- Palm up, narrow grip, pull ups
- Dips
- Overhead Press

