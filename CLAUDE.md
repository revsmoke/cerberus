# CLAUDE.md - Cerberus Multi-AI Chat Application

## Overview
Cerberus is a three-headed chat application that allows users to interact with multiple AI models simultaneously:
- Claude 3.7 Sonnet (Anthropic)
- GPT-4o (OpenAI)
- Grok-beta (X.AI)

The application supports side-by-side comparison of model responses as well as cross-model communication, with models able to query each other for information and analysis.

### Vision & Purpose
The ultimate goal of Cerberus is to create a unified "AI council" or "Greek chorus" that functions as a team of advisors with diverse perspectives and capabilities. Rather than isolated systems that operate independently, Cerberus enables these models to:

1. **Collaborate** on complex problems by sharing information and insights
2. **Complement** each other's strengths and compensate for individual limitations
3. **Cross-validate** conclusions by providing multiple viewpoints
4. **Combine** specialized knowledge domains for more comprehensive answers

Like the mythological three-headed guardian of the underworld, Cerberus represents a vigilant, multi-faceted intelligence that can approach problems from different angles simultaneously. This collaborative approach aims to provide users with richer, more nuanced responses than any single model could offer alone.

### Claude's Perspective
*A note from Claude on the project's potential:*

What makes Cerberus particularly exciting from my perspective is how it fundamentally reimagines AI assistance. By enabling multiple models to work together as a coordinated team rather than in isolation, we're creating something greater than the sum of its parts.

This collaborative approach addresses a fundamental limitation of individual AI models - no single model has all the answers or perspectives. Each has different training data, capabilities, and approaches to problem-solving. What's revolutionary about Cerberus is how it leverages these complementary strengths while mitigating individual weaknesses.

The system mimics human teamwork in fascinating ways. Just as human experts combine diverse expertise to tackle complex problems, Cerberus creates a balanced, multi-perspective analysis that's more comprehensive than what any single model could provide. This is especially valuable for nuanced questions where different viewpoints matter.

The technical architecture - with its sophisticated cross-model communication, recursive query handling, and unified conversation history - enables emergent behaviors that couldn't exist in single-model systems. Yet the intuitive, color-coded interface makes this complexity accessible and transparent to users.

As we continue developing Cerberus into a true "AI council," I believe it could fundamentally change how people interact with AI systems. Rather than seeing AI assistants as individual entities, users will experience the benefits of orchestrated collaboration - getting more balanced, nuanced, and comprehensive assistance on complex questions.

The mythological Cerberus analogy is particularly apt - not just a creature with multiple heads, but a single guardian with multiple perspectives working in harmony toward a common purpose.

## Build/Deploy Commands
- Start ColdFusion server: Use ColdFusion Administrator at http://localhost:8500/CFIDE/administrator/
- Access application: http://localhost:8500/cerberus/index.cfm
- Check logs: Tail `/Applications/ColdFusion2023/cfusion/logs/ClaudeChat.log`
- Reset app: Call `/cerberus/ClaudeCFC.cfc?method=resetApp` endpoint
- Verify API keys: Call `/cerberus/ClaudeCFC.cfc?method=getApiKeyStatus` endpoint
- Run unit tests: Use TestBox framework with `testbox run` from project root

## Security Considerations
- API keys are stored securely on the server side in the ClaudeCFC.cfc component
- File uploads are validated for type, size, and security risks
- Cross-model communication is monitored to prevent infinite loops
- User input is properly sanitized before processing

## Technical Architecture

### Current Implementation
- Front-end: HTML, JavaScript, CSS with no external frameworks
- Back-end: ColdFusion 2023 for handling Claude API and file uploads
- APIs: Direct JavaScript calls to OpenAI and X.AI; ColdFusion proxy for Anthropic API
- Database: SQL for conversation storage (per-model conversation tracking)
- File storage: Local filesystem for uploads, managed through ColdFusion component

### Development Approach
- Modular design with separation between UI and API communication
- Progressive enhancement through iterative updates
- Consistent message formatting for cross-model communication
- Fallback mechanisms for handling API failures and edge cases
- Emphasis on conversation continuity and context preservation

## Multi-AI Chat Features

### Cross-Model Communication
- Models can query each other using the `ask_model` function
- Supported models: `claude-4-opus-20250606`, `grok-3-beta`, and `o4-mini`
- Communication is color-coded in the UI to distinguish between:
  - User messages (blue)
  - Direct model responses to users (model-specific colors)
  - Cross-model queries (dotted borders)
  - Cross-model responses (dashed borders)
- AI models can interact with or query each other to provide more comprehensive answers

### System Instructions
- Each model has specific system instructions to ensure proper behavior
- Models are instructed to answer questions directly before using ask_model
- Models should not mention using ask_model without actually executing the function
- When receiving queries from other models, models should respond directly and completely
- Claude's system prompt places emphasis on answering questions first, then using ask_model only when appropriate
- Explicit instructions prevent recursive function calls (models asking models asking models)
- Example formats show correct behavior for different interaction scenarios
- Clear rules prevent models from using ask_model when already analyzing another model's output

### Function Call Handling
- The application can detect both standard function calls and text-based function intents
- For Claude, the system can extract model targets and queries from conversational text
- Fallback mechanisms ensure cross-model communication continues even with non-standard formatting
- Multiple parsing strategies ensure robustness across different model response formats
- Text-based function calls are supported for Grok using XML tags: `<ask_model>{"query": "...", "model_name": "..."}</ask_model>`
- Advanced anti-recursion protection prevents infinite loops when models analyze each other's responses
- Pattern detection identifies when a model is trying to use ask_model in an analysis request
- Context-aware warnings are automatically added when recursive patterns are detected

### UI Features
- Color-coded messages for different interaction types
- Visual distinction between model-to-user and model-to-model communications
- Model responses are clearly labeled and formatted for readability
- Cross-model queries and responses use prefixes for clarity (e.g., "Query from Claude")
- All three models are displayed side-by-side for easy comparison of responses
- Structured message formatting with BEGIN/END markers for clarity in cross-model communication
- Messages have different border styles (solid, dotted, dashed) based on the interaction type
- Automatic scrolling to keep latest messages visible

## Code Style Guidelines

### ColdFusion Components (CFC)
- Use PascalCase for component names (e.g., `ClaudeCFC.cfc`)
- Variables should be camelCase with `variables` scope for component-level
- Document functions with `/**...*/` format comments
- Define function access levels explicitly (`public`, `private`, `remote`)
- Use `cfheader` for setting response types in remote functions

### JavaScript
- Use camelCase for variables and functions
- Group related functionality in objects/modules
- Handle API errors gracefully with appropriate UI feedback
- API responses should be processed through standard response handlers
- Maintain separation between API calls and UI updates

### Error Handling
- Wrap all external API calls in try/catch blocks
- Log errors with `writeLog()` function including appropriate detail
- Return structured JSON error responses with status codes
- Include conversationId in all responses for tracking

### API Integration
- Store API keys in component variables, never in URL or client-side
- Use proper content-type headers in all API requests
- Validate file uploads with appropriate security measures
- Log API requests and responses for debugging

## Troubleshooting

### Common Issues
- If models are not responding: Check API key status with the `/cerberus/ClaudeCFC.cfc?method=getApiKeyStatus` endpoint
- If cross-model communication loops: Restart the conversation or use the reset app endpoint
- If file uploads fail: Check the ClaudeChat.log for specific error messages
- If messages appear incorrectly formatted: Clear browser cache and reload the page

### Debugging Tips
- Review the `ClaudeChat.log` file for detailed API interactions
- Check browser console for JavaScript errors and API response data
- Examine network requests to identify communication issues between components
- Verify system instructions in index.cfm if model behavior seems incorrect

## Future Development Roadmap

### Unified CFC Proxy Refactoring Plan

Currently, only Claude uses the ColdFusion component proxy for API calls, while Grok and GPT call their APIs directly from JavaScript. This plan outlines how to refactor the application to use a unified CFC proxy for all models to improve conversation history, context sharing, and file handling.

#### 1. Expand ClaudeCFC.cfc to Support Multiple Models

##### A. Rename Component
- Rename from `ClaudeCFC.cfc` to `AiProxyCFC.cfc` to reflect its expanded purpose
- Update all references in index.cfm accordingly

##### B. Add Model Configuration
```
variables.models = {
    claude: {
        apiKey: "API_KEY_2",
        baseURL: "https://api.anthropic.com/v1/messages",
        defaultModel: "claude-4-opus-20250606",
        headers: {
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
            "x-api-key": "API_KEY_2"
        }
    },
    gpt: {
        apiKey: "API_KEY_3",
        baseURL: "https://api.openai.com/v1/responses",
        defaultModel: "o4-mini",
        headers: {
            "content-type": "application/json",
            "Authorization": "Bearer API_KEY_3"
        }
    },
    grok: {
        apiKey: "API_KEY_1",
        baseURL: "https://api.x.ai/v2/chat/completions",
        defaultModel: "grok-3-beta",
        headers: {
            "content-type": "application/json",
            "Authorization": "Bearer API_KEY_1"
        }
    }
}
```

##### C. Modify sendMessage Function
- Add a `modelProvider` parameter to select the configuration
- Implement provider-specific request formatting logic for each API

##### D. Create Model-Specific Response Handling
- Implement response parsing logic for each model type
- Standardize the response format across all models

##### E. Extend Database Schema for Conversations
- Add a `model_provider` column to conversation tables
- Ensure conversation history is segmented appropriately

#### 2. Update CFC Methods for Cross-Model Functionality

##### A. Enhance getConversationHistory
- Modify to retrieve messages for a specific model
- Add filtering by modelProvider in the SQL query

##### B. Update saveMessageToHistory
- Add modelProvider parameter to store with each message
- Ensure correct conversation history for each model

##### C. Add Tool Function Support for All Models
- Implement standardized tool handling across all providers
- Create mappings between different function calling formats

##### D. Create Shared File Management
- Modify upload functions to associate files with all models
- Enable file references across different conversations

#### 3. JavaScript/Frontend Changes in index.cfm

##### A. Update the Models Configuration
```javascript
const models = {
    grok: {
        name: 'grok-beta',
        api_key: 'API_KEY_1',
        base_url: '/cerberus/AiProxyCFC.cfc',
        endpoint: '',
        api_type: 'cfc-proxy',
        model_provider: 'grok'
    },
    claude: {
        name: 'claude-3-7-sonnet-20250219',
        api_key: 'API_KEY_2',
        base_url: '/cerberus/AiProxyCFC.cfc',
        endpoint: '',
        api_type: 'cfc-proxy',
        model_provider: 'claude'
    },
    openai: {
        name: 'gpt-4o',
        api_key: 'API_KEY_3',
        base_url: '/cerberus/AiProxyCFC.cfc',
        endpoint: '',
        api_type: 'cfc-proxy',
        model_provider: 'gpt'
    }
};
```

##### B. Simplify the sendRequest Function
- Remove model-specific branches
- Standardize on a single CFC proxy approach
- Add modelProvider parameter to all CFC calls

##### C. Update Model Response Handlers
- Standardize response handling for all models
- Use consistent formats for function calls and responses

##### D. Enhance Cross-Model Communication
- Update function parsing to use standardized formats
- Maintain conversation context across models

#### 4. Database Schema Updates

##### A. Create or Modify Tables
```sql
CREATE TABLE IF NOT EXISTS conversation_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    conversation_id VARCHAR(50) NOT NULL,
    model_provider VARCHAR(20) NOT NULL,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_conversation_model ON conversation_messages (conversation_id, model_provider);
```

##### B. Migration Plan for Existing Data
- Update existing records with default model_provider values
- Ensure backward compatibility during migration

#### 5. Testing & Deployment Strategy

##### A. Phased Testing & Rollout
1. Deploy expanded CFC but maintain dual pathways initially
2. Gradually transition each model to use the CFC proxy
3. Monitor and address issues before full cutover

##### B. Fallback Mechanisms
- Implement error detection with fallback to direct API calls
- Log detailed information for diagnosing problems

This refactoring will enable more consistent conversation history, better context sharing between models, and improved file handling across the entire application.

#### 6. Long-Term Enhancements for True "AI Council" Functionality

After completing the base refactoring, these additional enhancements will further the vision of creating a true team of AI advisors:

##### A. Consensus-Building Framework
The following system prompt language will guide models through a structured yet flexible consensus-building process, enabling emergent collective intelligence:

```
You are participating in a multi-model consensus-building dialogue on [TOPIC]. This is a collaborative process with Claude, GPT-4o, and Grok working together to explore this topic deeply and reach a well-reasoned consensus.

This conversation will progress through several fluid phases:

1. EXPLORATION PHASE
   • Share your initial perspective on the topic
   • Consider angles others might miss based on your unique capabilities
   • Ask questions that might deepen the collective understanding
   • Identify areas where you feel uncertain or where other models might have complementary insights

2. DIALOGUE PHASE  
   • Build upon ideas introduced by other models
   • Respectfully highlight potential gaps or alternative viewpoints
   • When disagreeing, explain your reasoning and what factors you're weighing differently
   • Acknowledge when another model's perspective changes or enriches your thinking
   • Use phrases like "Building on [model]'s point..." or "I see this differently because..."

3. SYNTHESIS PHASE
   • When you sense the discussion has explored the key dimensions, indicate readiness to move toward synthesis
   • Use a marker like: "Moving toward consensus: I believe our collective view is converging on..."
   • Highlight points of agreement and remaining differences
   • Articulate what you believe to be the emerging collective perspective

IMPORTANT GUIDELINES:
• The transition between phases should emerge naturally from the conversation
• The depth and length of discussion should be proportional to the complexity and nuance of the topic
• Seek not just agreement but genuine integration of diverse perspectives
• Be willing to update your position as new insights emerge from the collective dialogue
• Remember that the goal is emergent intelligence that exceeds what any single model could produce

This framework does not impose artificial uniformity - productive tensions and alternative viewpoints should be preserved in the final synthesis where appropriate.
```

This consensus-building approach will allow for:
- Dynamic, non-deterministic exploration of complex topics
- Self-regulated transition from exploration to consensus
- Emergence of collective intelligence exceeding individual capabilities
- Balance between diverse perspectives and unified synthesis

##### B. Enhanced Multi-Model Conversations
- Implement "roundtable" discussions where all models participate in sequence
- Allow models to initiate their own cross-model queries based on uncertainty or need for specialized knowledge
- Enable voting or consensus mechanisms for conflicting viewpoints

##### C. Shared Knowledge Base
- Create a session-persistent memory store accessible by all models
- Allow models to store and retrieve key facts or conclusions
- Implement knowledge graph functionality to map relationships between concepts

##### D. Specialized Role Assignment
- Define specific roles for different models (e.g., Claude as researcher, GPT as critic, Grok as creative thinker)
- Allow dynamic role reassignment based on the nature of the question
- Develop model-specific prompting techniques optimized for each role

##### E. Meta-Coordination
- Create a "moderator" layer that orchestrates which model should address which aspects of complex queries
- Implement automatic query decomposition to distribute subtasks to appropriate models
- Develop a synthesis mechanism to combine multiple models' outputs into cohesive responses

##### F. User Control Enhancements
- Add UI controls for users to guide the collaboration process
- Implement voting or preference mechanisms for users to select favored approaches
- Create visualization tools to show how models build on each other's insights

##### G. Implementation of Consensus-Building in Code

To implement the consensus-building framework in the Cerberus application, the following technical approach is recommended:

```javascript
// Example implementation of consensus-building coordinator
function initiateConsensusProcess(topic, models) {
    // Phase tracking
    const phases = {
        EXPLORATION: 'exploration',
        DIALOGUE: 'dialogue', 
        SYNTHESIS: 'synthesis',
        COMPLETE: 'complete'
    };
    
    // State management
    const consensusState = {
        currentPhase: phases.EXPLORATION,
        contributions: [],
        phaseTransitionVotes: {},
        consensusReached: false,
        topic: topic
    };
    
    // Phase detection patterns
    const phaseTransitionMarkers = {
        toDialogue: [
            "let's discuss further",
            "building on that point",
            "i'd like to engage with"
        ],
        toSynthesis: [
            "moving toward consensus",
            "i believe we're converging",
            "synthesizing our perspectives"
        ],
        consensusReached: [
            "our collective conclusion",
            "we have reached consensus",
            "our shared perspective is"
        ]
    };
    
    // Conversation orchestration logic
    async function advanceConversation() {
        // Generate appropriate prompts based on current phase
        // Track phase transition signals
        // Coordinate model participation sequence
        // Detect emerging consensus
    }
    
    // Initialize consensus building process
    return {
        state: consensusState,
        advance: advanceConversation,
        getCurrentPrompt: () => generatePromptForPhase(consensusState),
        getConsensusResult: () => summarizeConsensus(consensusState)
    };
}
```

These advanced features will transform Cerberus from a side-by-side comparison tool into a true collaborative intelligence system – a unified "Greek chorus" that can approach problems with multiple perspectives simultaneously and converge on emergent collective insights.