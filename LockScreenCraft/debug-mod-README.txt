# LockScreenCraft Debug Features Documentation

This branch preserves the development and testing features that were removed from the App Store submission version of LockScreenCraft. This comprehensive guide documents all debug-only functionality to aid future reimplementation.

## Table of Contents
- [Overview of Debug Architecture](#overview-of-debug-architecture)
- [Text File Processing System](#text-file-processing-system)
- [File System Integration](#file-system-integration)
- [Debug UI Elements](#debug-ui-elements)
- [Debugging Helpers](#debugging-helpers)
- [Implementation Details](#implementation-details)
- [Usage Guide](#usage-guide)
- [Reimplementation Guide](#reimplementation-guide)

## Overview of Debug Architecture

Debug features in LockScreenCraft are designed to:
1. Accelerate testing of multiple text inputs
2. Provide deeper insight into the wallpaper generation process
3. Enable file system access for saving and loading
4. Support batch processing of wallpapers

These features are isolated using Swift's conditional compilation with `#if DEBUG` blocks throughout the codebase.

## Text File Processing System

### Core Functionality

The text file processing system allows you to:
- Load text files from the app bundle
- Process multiple files in sequence
- Automatically generate wallpapers from each file
- Navigate through files with progress tracking

### Implementation in WallpaperGeneratorViewModel

