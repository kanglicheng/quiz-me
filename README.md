# iOS Quiz App

A simple iOS quiz application built with SwiftUI that tests users with randomized questions and provides feedback on their answers. The app also features motion detection and screenshot capabilities.

![Quiz App Screenshots](app_screenshots.png)

## Features

- **Randomized Questions**: Dynamically presents questions from a question bank
- **Intelligent Feedback**:
  - Correct answers trigger positive reinforcement
  - Incorrect answers provide learning opportunities by showing the correct answer
- **Motion Detection**: Automatically pauses the quiz when the device is placed flat on a surface
- **Screenshot Functionality**: Capture and view quiz moments with built-in screenshot tools

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern with SwiftUI's state management approach:

### Key Components

#### Models
- **Question**: Encapsulates question data including text, options, and correct answer index
- Serves as the core data structure for quiz content

#### Manager Classes (ViewModels)
- **QuizManager**: Controls quiz state, question selection, and scoring logic
- **MotionManager**: Handles device orientation detection via CoreMotion
- **ScreenshotManager**: Manages screenshot capturing, storage, and retrieval

#### Views
- **HomeView**: Entry point displaying welcome message and navigation options
- **QuizView**: Presents questions, handles user interaction, and displays results
- **ScreenshotView**: Displays captured screenshots with appropriate UI controls

## Technical Implementation

### SwiftUI Framework
The entire UI is implemented using SwiftUI, Apple's modern declarative UI framework.

### State Management
- **@State**: For view-local state (e.g., navigation flags, animation states)
- **@StateObject**: For owning and initializing observable objects
- **@EnvironmentObject**: For passing manager objects down the view hierarchy
- **@Published**: For reactive property updates within observable objects

