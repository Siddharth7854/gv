# Copilot Instructions for Grievance Employee App

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## Project Overview

This is a professional Flutter mobile application for government employee grievance management with SQL Server backend integration.

## Development Guidelines

### Code Style & Architecture

- Use **Flutter Riverpod** for state management
- Follow **Clean Architecture** principles with proper separation of concerns
- Implement **Repository Pattern** for data access
- Use **Professional Government Design System** with consistent colors and typography
- Ensure all UI components follow accessibility standards

### Design Standards

- **Color Scheme**: Professional government blues, grays, and accent colors
- **Typography**: Use Google Fonts (Roboto, Inter) for consistency
- **Animations**: Subtle, professional animations using flutter_animate
- **Spacing**: Consistent 8px grid system
- **Components**: Material 3 design with custom government theming

### Data Management

- **Backend**: SQL Server with REST API endpoints
- **Local Storage**: Hive for offline support and caching
- **Authentication**: JWT token-based authentication
- **Sync**: Implement offline-first approach with background sync

### Security Considerations

- Implement proper input validation and sanitization
- Use secure token storage
- Follow government security standards
- Implement proper error handling without exposing sensitive information

### Testing Requirements

- Write unit tests for all business logic
- Implement widget tests for UI components
- Create integration tests for critical user flows
- Mock external dependencies properly

### Performance Guidelines

- Optimize network calls with proper caching
- Implement lazy loading for large lists
- Use image optimization and caching
- Monitor memory usage and prevent leaks

### Government Compliance

- Ensure accessibility compliance (WCAG guidelines)
- Implement proper logging and audit trails
- Follow data privacy regulations
- Maintain professional UX standards suitable for government employees
