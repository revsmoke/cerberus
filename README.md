# Cerberus: Multi-Model AI Collaboration System

A ColdFusion-based application that enables multiple AI models to work together as a cohesive team, providing richer, more nuanced responses than any single model could offer alone. Cerberus currently integrates:

- Claude Opus 4 (Anthropic)
- o4-mini (OpenAI)
- Grok 3 Beta (X.AI)

## Vision!

Like the mythological three-headed guardian, Cerberus represents a vigilant, multi-faceted intelligence system that can approach problems from different angles simultaneously. The ultimate goal is to create a unified "AI council" or "Greek chorus" that functions as a team of advisors with diverse perspectives and capabilities.

Rather than isolated systems that operate independently, Cerberus enables these models to:
- **Collaborate** on complex problems by sharing information and insights
- **Complement** each other's strengths and compensate for individual limitations
- **Cross-validate** conclusions by providing multiple viewpoints
- **Combine** specialized knowledge domains for more comprehensive answers

## Features

- **Advanced Cross-Model Communication**: Models can query each other for information, analysis, and perspectives
- **Visual Distinction**: Color-coded messages differentiate between user messages, model responses, and cross-model communication
- **Anti-Recursion Protection**: Sophisticated mechanisms prevent infinite loops in cross-model conversations
- **Conversation History**: Per-model conversation tracking with unified backend storage
- **Side-by-Side Comparison**: View all three models' responses simultaneously for easy comparison
- **File Handling**: Upload and share images, PDFs, and other documents across models
- **Proxy Architecture**: CORS-compliant ColdFusion proxy for API communication

## Technical Architecture

- **Backend**: ColdFusion 2023 with component-based API proxying
- **Frontend**: Pure HTML, CSS, JavaScript (no external frameworks)
- **APIs**: Anthropic, OpenAI, X.AI with unified response handling
- **Database**: SQL storage for conversation history and context
- **File System**: Local storage for uploaded files

## Future Development

Cerberus is evolving toward a true consensus-building system with these planned enhancements:

- **Unified CFC Proxy**: Refactoring to route all model communication through ColdFusion components
- **Consensus Framework**: Structured yet flexible process for models to explore topics and converge on collective insights
- **Shared Knowledge Base**: Session-persistent memory accessible by all models
- **Specialized Role Assignment**: Dynamic allocation of roles to models based on query characteristics
- **Meta-Coordination**: Orchestration layer for complex query handling across models

For detailed development roadmap, see CLAUDE.md in the repository.

## Setup

1. Install ColdFusion 2023
2. Place files in your ColdFusion wwwroot directory
3. Access the application at: http://localhost:8500/cerberus/index.cfm
4. For enhanced capabilities, ensure database connectivity is configured

## API Keys

The application requires API keys for each model:
- Anthropic Claude: `x-api-key` header 
- OpenAI: Bearer token authentication
- X.AI: Bearer token authentication

Store your API keys securely in the `ClaudeCFC.cfc` component.

## Why Cerberus Matters

The development of Cerberus represents an important step forward in AI assistance technology. By enabling multiple models to collaborate rather than compete, we can:

1. **Reduce individual model biases** through cross-validation and perspective sharing
2. **Leverage specialized capabilities** of different model architectures
3. **Create emergent intelligence** that exceeds what any single model could produce
4. **Provide more balanced, nuanced responses** to complex queries
5. **Explore the potential of non-hierarchical AI collaboration** as a new paradigm

## Security Considerations

- API keys are stored securely on the server side in the ClaudeCFC.cfc component
- File uploads are validated for type, size, and security risks
- Cross-model communication is monitored to prevent infinite loops
- User input is properly sanitized before processing

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

Key areas where contributions would be especially valuable:
- Implementing the unified CFC proxy architecture
- Enhancing the consensus-building framework
- Improving the UI for better visualization of cross-model collaboration
- Adding support for additional AI models
- Creating specialized tools for specific knowledge domains
