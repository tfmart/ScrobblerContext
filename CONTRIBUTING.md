# Contributing to ScrobblerContext

Thank you for your interest in contributing to ScrobblerContext! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites

- Swift 6.0+ ([Download](https://swift.org/download/))
- macOS 13.0+ or Linux with Swift support
- Last.fm API credentials for testing ([Get them here](https://www.last.fm/api/account/create))
- Git for version control

### Development Setup

1. **Fork and clone the repository**:
   ```bash
   git clone https://github.com/your-username/ScrobblerContext.git
   cd ScrobblerContext
   ```

2. **Install dependencies**:
   ```bash
   swift package resolve
   ```

3. **Set up environment variables for testing**:
   ```bash
   export LASTFM_API_KEY="your_test_api_key"
   export LASTFM_SECRET_KEY="your_test_secret_key"
   ```

4. **Build and test**:
   ```bash
   swift build
   swift test
   swift run ScrobblerContext
   ```

## 🏗 Project Structure

```
ScrobblerContext/
├── Sources/ScrobblerContext/
│   ├── Extensions/           # Swift extensions and utilities
│   ├── Models/              # Data models and input structures
│   │   ├── Albums/          # Album-related models
│   │   ├── Artists/         # Artist-related models
│   │   ├── Scrobble/        # Scrobbling models
│   │   ├── Tracks/          # Track-related models
│   │   └── Users/           # User-related models
│   ├── Server/              # MCP server configuration
│   ├── Services/            # Core business logic
│   └── Tools/               # MCP tool implementations
│       └── Categories/      # Tool categories (Auth, Artist, Album, etc.)
├── Tests/                   # Unit tests
├── docs/                    # Generated documentation
└── .github/workflows/       # CI/CD workflows
```

## 🛠 Development Guidelines

### Code Style

- Follow Swift naming conventions
- Use clear, descriptive variable and function names
- Add documentation comments for public APIs
- Keep functions focused and single-purpose
- Use `async/await` for asynchronous operations

### Example of good documentation:

```swift
/// Searches for artists matching the given query.
///
/// - Parameters:
///   - query: The search term for finding artists
///   - limit: Maximum number of results to return (default: 10)
///   - page: Page number for pagination (default: 1)
/// - Returns: Array of matching artists
/// - Throws: `ToolError` if the search fails
func searchArtist(query: String, limit: Int = 10, page: Int = 1) async throws -> [SBKArtist]
```

### Adding New Tools

When adding new MCP tools:

1. **Create the input model** in the appropriate `Models/` subdirectory
2. **Implement the tool logic** in the relevant tool category class
3. **Add the tool to `ToolName` enum** with proper category assignment
4. **Update the tool registration** in the appropriate category
5. **Add comprehensive documentation** explaining the tool's purpose and usage
6. **Write tests** for the new functionality

### Example tool implementation:

```swift
/// Searches for albums by name
/// - Parameter input: Search parameters including query and pagination
/// - Returns: Formatted search results with album information
func searchAlbum(_ input: SearchAlbumInput) async throws -> ToolResult {
    let albums = try await lastFMService.searchAlbum(
        query: input.query,
        limit: input.limit,
        page: input.page
    )
    
    return ResponseFormatters.formatAlbumSearchResults(albums)
}
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run specific test
swift test --filter TestClassName
```

### Testing with Real API

For integration testing with the Last.fm API:

1. Use test API credentials (not your personal ones)
2. Be mindful of rate limits
3. Test both success and error scenarios
4. Clean up any data created during tests

### Mock Testing

Use mock services for unit tests to avoid API dependencies:

```swift
class MockLastFMService: LastFMService {
    var mockResults: [SBKArtist] = []
    
    override func searchArtist(query: String, limit: Int, page: Int) async throws -> [SBKArtist] {
        return mockResults
    }
}
```

## 📝 Documentation

### DocC Documentation

We use Swift DocC for API documentation:

```bash
# Generate documentation
swift package generate-documentation --target ScrobblerContext

# Preview documentation locally
swift package --disable-sandbox preview-documentation --target ScrobblerContext
```

### Writing Good Documentation

- Use clear, concise language
- Include code examples for complex functionality
- Document parameters, return values, and thrown errors
- Add usage examples for public APIs
- Keep documentation up-to-date with code changes

## 🔄 Pull Request Process

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Write clean, documented code
   - Add tests for new functionality
   - Update documentation as needed

3. **Test thoroughly**:
   ```bash
   swift build
   swift test
   # Test manually with MCP client
   ```

4. **Commit with clear messages**:
   ```bash
   git commit -m "Add search functionality for track recommendations"
   ```

5. **Push and create PR**:
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Fill out the PR template** with:
   - Clear description of changes
   - Testing performed
   - Breaking changes (if any)
   - Related issues

### PR Guidelines

- Keep PRs focused on a single feature/fix
- Write clear commit messages
- Include tests for new functionality
- Update documentation for API changes
- Ensure CI passes before requesting review

## 🐛 Reporting Issues

When reporting bugs:

1. **Use the issue template**
2. **Provide clear reproduction steps**
3. **Include relevant environment information**:
   - Swift version
   - Operating system
   - MCP client used
4. **Attach relevant logs** (remove sensitive information)

### Issue Labels

- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Improvements to documentation
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention is needed

## 💡 Feature Requests

For new features:

1. **Check existing issues** to avoid duplicates
2. **Describe the use case** clearly
3. **Explain the proposed solution**
4. **Consider backwards compatibility**

## 🔒 Security

- **Never commit API keys or secrets**
- **Use environment variables** for sensitive configuration
- **Report security vulnerabilities** privately via email
- **Follow secure coding practices**

## 📋 Code Review Checklist

Before submitting a PR, ensure:

- [ ] Code builds without warnings
- [ ] All tests pass
- [ ] New functionality is tested
- [ ] Documentation is updated
- [ ] API keys/secrets are not committed
- [ ] Code follows project style guidelines
- [ ] Breaking changes are documented

## 🤝 Community

- Be respectful and inclusive
- Help other contributors
- Share knowledge and best practices
- Provide constructive feedback

## 📚 Resources

- [Swift Documentation](https://docs.swift.org/)
- [Model Context Protocol Spec](https://modelcontextprotocol.io/)
- [Last.fm API Documentation](https://www.last.fm/api)
- [ScrobbleKit Library](https://github.com/tfmart/ScrobbleKit)

## ❓ Questions?

If you have questions about contributing:

- Check existing [GitHub Discussions](https://github.com/tfmart/ScrobblerContext/discussions)
- Open a new discussion for general questions
- Create an issue for specific problems

Thank you for contributing to ScrobblerContext! 🎵