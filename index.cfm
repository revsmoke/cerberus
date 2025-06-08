<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cerberus Multi-AI Chat App</title>
    <style>
        /* Basic styling for layout clarity */
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        .chat-container {
            display: flex;
            justify-content: space-between;
        }
        .model-section {
            width: 30%;
            border: 1px solid #ccc;
            padding: 10px;
            margin: 10px;
        }
        .conversation {
            height: 400px;
            overflow-y: scroll;
            border: 1px solid #eee;
            padding: 10px;
            margin-bottom: 10px;
        }
        .user-query, .ai-response, .function-call, .model-query, .model-response {
            margin-bottom: 10px;
            padding: 8px;
            border-radius: 5px;
        }
        
        /* User messages */
        .user-query {
            font-weight: bold;
            color: #0055aa;
            background-color: #e6f0ff;
            border-left: 3px solid #0055aa;
        }
        
        /* Direct model responses to user */
        .grok-response {
            color: #d14000;
            background-color: #fff4f0;
            border-left: 3px solid #d14000;
        }
        .claude-response {
            color: #007766;
            background-color: #f0fffc;
            border-left: 3px solid #007766;
        }
        .openai-response {
            color: #555500;
            background-color: #ffffee;
            border-left: 3px solid #555500;
        }
        
        /* Model asking another model */
        .grok-query {
            color: #aa4000;
            background-color: #fff6f0;
            border-left: 3px dotted #aa4000;
            font-style: italic;
        }
        .claude-query {
            color: #005544;
            background-color: #f0fff8;
            border-left: 3px dotted #005544;
            font-style: italic;
        }
        .openai-query {
            color: #555500;
            background-color: #fdfde8;
            border-left: 3px dotted #555500;
            font-style: italic;
        }
        
        /* Response to another model's query */
        .model-response {
            color: #333399;
            background-color: #f0f0ff;
            border-left: 3px dashed #333399;
        }
        
        /* Function calls */
        .function-call {
            color: #aa3377;
            background-color: #fff0f8;
            border-left: 3px solid #aa3377;
            font-style: italic;
        }
        .input-area {
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1>Cerberus Multi-AI Chat App</h1>
    <div class="chat-container">
        <div class="model-section" id="grok-section">
            <h2>Grok 3 Beta</h2>
            <div class="conversation" id="grok-conversation"></div>
        </div>
        <div class="model-section" id="claude-section">
            <h2>Claude Opus 4</h2>
            <div class="conversation" id="claude-conversation"></div>
        </div>
        <div class="model-section" id="openai-section">
            <h2>OpenAI (o4-mini)</h2>
            <div class="conversation" id="openai-conversation"></div>
        </div>
    </div>
    <div class="input-area">
        <input type="text" id="user-input" placeholder="Type your query here..." style="width: 80%;">
        <button id="submit-button">Send</button>
    </div>

    <script>
       document.addEventListener('DOMContentLoaded', function() {
    // **1. Model Definitions**
    const models = {
        grok: {
            name: 'grok-3-beta',
            api_key: 'API_KEY_1',
            base_url: '/cerberus/AiProxyCFC.cfc',
            endpoint: '',
            api_type: 'cfc-proxy',
            model_provider: 'grok'
        },
        claude: {
            name: 'claude-opus-4-20250514',
            api_key: 'API_KEY_2',
            base_url: '/cerberus/AiProxyCFC.cfc',
            endpoint: '',
            api_type: 'cfc-proxy',
            model_provider: 'claude'
        },
        openai: {
            name: 'o4-mini',
            api_key: 'API_KEY_3',
            base_url: '/cerberus/AiProxyCFC.cfc',
            endpoint: '',
            api_type: 'cfc-proxy',
            model_provider: 'gpt'
        }
    };

    // **2. Conversation Histories**
    const conversations = {
        grok: [{
            role: 'system',
            content: `You are Grok 3 Beta, developed by xAI. This is a multi-AI chat interface where each message is directed to a specific AI.

IMPORTANT: This interface prefixes messages with "Grok:" automatically when they are directed to you, so you should always respond directly to the user's query without mentioning the prefix.

When messages begin with "Grok:", simply respond to the content that follows. For example, if you see "Grok: hello", just respond with a greeting.

FUNCTION CALLING INSTRUCTIONS:
When you need to query another AI model, use the ask_model function. You can call this function with ONE of the following formats:

1. PREFERRED METHOD - Use proper function calling:
   ask_model({ query: "What is your opinion on X?", model_name: "claude-opus-4-20250514" })

2. ALTERNATE METHOD - Use XML tags:
   <ask_model>{ "query": "What is your question?", "model_name": "claude-opus-4-20250514" }</ask_model>

Available models are:
- "grok-3-beta" (yourself)
- "claude-opus-4-20250514" (Claude)
- "o4-mini" (GPT)

IMPORTANT RULES TO PREVENT INFINITE LOOPS:
1. When a query comes from another model via ask_model, respond directly and completely to their question. DO NOT USE THE ASK_MODEL FUNCTION IN YOUR RESPONSE TO ANOTHER MODEL'S QUERY.

2. When analyzing or responding to another model's output, NEVER suggest using ask_model again. Just analyze what was provided.

3. Make sure to format function calls EXACTLY as shown, with proper JSON syntax and quotes.`
        }],
        claude: [{
            role: 'system',
            content: `You are Claude Opus 4, developed by Anthropic. This is a multi-AI chat interface.

IMPORTANT INSTRUCTIONS FOR CLAUDE:

1. When asked a direct question, ALWAYS ANSWER THE QUESTION FIRST with your own knowledge before considering using ask_model.

2. Only use the ask_model function when:
   - Explicitly directed by the user
   - The question requires expertise beyond your knowledge
   - You need to compare different AI perspectives

3. NEVER say "I'll ask another model" and then fail to use ask_model. If your response indicates you will ask another model, you MUST execute the ask_model function.

4. When a query comes from another model via ask_model, respond directly and completely to their question. DO NOT USE THE ASK_MODEL FUNCTION IN YOUR RESPONSE TO ANOTHER MODEL'S QUERY. This creates infinite loops.

5. When analyzing or responding to another model's output, NEVER suggest using ask_model again. Just analyze what was provided.

6. Available models:
   - "grok-3-beta" (Grok)
  - "claude-opus-4-20250514" (yourself)
   - "o4-mini" (GPT)

EXAMPLE OF CORRECT BEHAVIOR:
✓ Question: "What is dark matter?"
✓ Good response: "Dark matter is a hypothetical form of matter that doesn't interact with the electromagnetic force but would still have gravitational effects. It's thought to make up about 85% of the matter in the universe. [Your complete explanation here...]"

✓ Question: "Can you ask GPT what dark matter is?"
✓ Good response: [Call ask_model with query to GPT, then analyze response WITHOUT calling ask_model again]

✓ Question from Grok via ask_model: "What is dark matter?"
✓ Good response: [Direct, complete answer to Grok's question WITHOUT mentioning ask_model]

✓ Request to analyze another model's output:
✓ Good response: [Analyze the content directly WITHOUT suggesting to ask other models]
`
        }],
        openai: [{
            role: 'system',
            content: `You are o4-mini, developed by OpenAI. This is a multi-AI chat interface.

IMPORTANT INSTRUCTIONS FOR GPT:

1. When asked a direct question, ALWAYS ANSWER THE QUESTION FIRST with your own knowledge before considering using ask_model.

2. Only use the ask_model function when:
   - Explicitly directed by the user
   - The question requires expertise beyond your knowledge
   - You need to compare different AI perspectives

3. NEVER say "I'll ask another model" and then fail to use ask_model. If your response indicates you will ask another model, you MUST execute the ask_model function.

4. When a query comes from another model via ask_model, respond directly and completely to their question. DO NOT USE THE ASK_MODEL FUNCTION IN YOUR RESPONSE TO ANOTHER MODEL'S QUERY. This creates infinite loops.

5. When analyzing or responding to another model's output, NEVER suggest using ask_model again. Just analyze what was provided.

6. Available models:
   - "grok-3-beta" (Grok)
  - "claude-opus-4-20250514" (Claude)
   - "o4-mini" (yourself)

EXAMPLE OF CORRECT BEHAVIOR:
✓ Question: "What is dark matter?"
✓ Good response: "Dark matter is a hypothetical form of matter that doesn't interact with the electromagnetic force but would still have gravitational effects. It's thought to make up about 85% of the matter in the universe. [Your complete explanation here...]"

✓ Question: "Can you ask Claude what dark matter is?"
✓ Good response: [Call ask_model with query to Claude, then analyze response WITHOUT calling ask_model again]

✓ Question from Grok via ask_model: "What is dark matter?"
✓ Good response: [Direct, complete answer to Grok's question WITHOUT mentioning ask_model]

✓ Request to analyze another model's output:
✓ Good response: [Analyze the content directly WITHOUT suggesting to ask other models]
`
        }]
    };

    // **3. Function Definition for ask_model**
    const askModelFunction = {
        name: 'ask_model',
        description: 'Ask a question to another AI model',
        parameters: {
            type: 'object',
            properties: {
                query: { type: 'string', description: 'The question to ask' },
                model_name: { type: 'string', description: 'The name of the model to ask', enum: ['grok-3-beta', 'claude-opus-4-20250514', 'o4-mini'] }
            },
            required: ['query', 'model_name']
        }
    };

    // **4. Handle User Input**
    const submitButton = document.getElementById('submit-button');
    const userInput = document.getElementById('user-input');
    submitButton.addEventListener('click', () => {
        const query = userInput.value.trim();
        if (query) {
            handleUserQuery(query);
            userInput.value = ''; // Clear input field
        }
    });

    userInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            const query = userInput.value.trim();
            if (query) {
                handleUserQuery(query);
                userInput.value = ''; // Clear input field
            }
        }
    });

    // **5. Process User Query**
    async function handleUserQuery(query) {
        // Check if the message is addressed to a specific model
        const lowercaseQuery = query.toLowerCase();
        const isAddressedToGrok = lowercaseQuery.startsWith("grok:");
        const isAddressedToClaude = lowercaseQuery.startsWith("claude:");
        const isAddressedToGPT = lowercaseQuery.startsWith("gpt:") || lowercaseQuery.startsWith("openai:");
        
        // If addressed to a specific model, only send to that one
        if (isAddressedToGrok || isAddressedToClaude || isAddressedToGPT) {
            for (const modelKey in models) {
                // Determine if this model should respond
                const shouldRespond = 
                    (modelKey === 'grok' && isAddressedToGrok) ||
                    (modelKey === 'claude' && isAddressedToClaude) ||
                    (modelKey === 'openai' && isAddressedToGPT);
                
                // Always display the message in all conversations
                displayMessage(modelKey, 'user', query);
                
                // But only add to conversation and request response from the addressed model
                if (shouldRespond) {
                    const model = models[modelKey];
                    // Remove the prefix from the query (e.g., "Claude: hello" -> "hello")
                    let cleanedQuery = query;
                    if (isAddressedToGrok && query.toLowerCase().startsWith("grok:")) {
                        cleanedQuery = query.substring(5).trim();
                    } else if (isAddressedToClaude && query.toLowerCase().startsWith("claude:")) {
                        cleanedQuery = query.substring(7).trim();
                    } else if ((isAddressedToGPT && query.toLowerCase().startsWith("gpt:")) || 
                             (isAddressedToGPT && query.toLowerCase().startsWith("openai:"))) {
                        cleanedQuery = query.toLowerCase().startsWith("gpt:") ? 
                            query.substring(4).trim() : query.substring(7).trim();
                    }
                    
                    conversations[modelKey].push({ role: 'user', content: cleanedQuery });
                    const response = await sendRequest(model, conversations[modelKey]);
                    handleModelResponse(modelKey, response);
                }
            }
        } 
        // If not addressed to a specific model, send to all models directly without prefixes
        else {
            for (const modelKey in models) {
                const model = models[modelKey];
                
                // Display original query to user
                displayMessage(modelKey, 'user', query);
                
                // Add query directly to conversation without prefixes
                conversations[modelKey].push({ role: 'user', content: query });
                
                const response = await sendRequest(model, conversations[modelKey]);
                handleModelResponse(modelKey, response);
            }
        }
    }

    // **6. Display Messages**
    function displayMessage(modelKey, type, content, sourceModel = null) {
        const conversationDiv = document.getElementById(`${modelKey}-conversation`);
        const messageDiv = document.createElement('div');
        
        // Apply appropriate CSS class based on message type and source
        if (type === 'user') {
            // User messages always get the user-query class
            messageDiv.classList.add('user-query');
        } else if (type === 'function') {
            // Function calls get the function-call class
            messageDiv.classList.add('function-call');
        } else if (type === 'ai') {
            if (sourceModel) {
                // This is a response to another model's query
                messageDiv.classList.add('model-response');
                // Add a prefix to show which model asked the question
                content = `[Response to ${sourceModel}] ${content}`;
            } else {
                // Direct response to user - use model-specific response class
                messageDiv.classList.add(`${modelKey}-response`);
            }
        } else if (type === 'model-query') {
            // One model asking another - use source model's query class
            messageDiv.classList.add(`${sourceModel}-query`);
            // Add a prefix to show it's a query from another model
            content = `[Query from ${sourceModel}] ${content}`;
        }
        
        messageDiv.textContent = content;
        conversationDiv.appendChild(messageDiv);
        conversationDiv.scrollTop = conversationDiv.scrollHeight; // Auto-scroll to latest message
    }

    // **7. Send API Requests**
    async function sendRequest(model, conversation) {
        let response, body;
        
        // Handle Claude API requests through ColdFusion proxy to avoid CORS
        if (model.api_type === 'anthropic') {
            try {
                // Extract latest user message
                const latestUserMessage = [...conversation].reverse().find(msg => msg.role === 'user')?.content || '';
                
                // Extract conversation ID if it exists
                let conversationId = "";
                if (conversation.conversationId) {
                    conversationId = conversation.conversationId;
                }
                
                // Check if the user is asking Claude to query another model
                let enhancedMessage = latestUserMessage;
                if (typeof latestUserMessage === 'string' && !latestUserMessage.startsWith('[Query from')) {
                    // If user is explicitly asking Claude to use ask_model but not using proper function call format
                    const askAnotherModelPatterns = [
                        /ask\s+(grok|gpt|openai)/i,
                        /what\s+does\s+(grok|gpt|openai)\s+think/i,
                        /get\s+(grok|gpt|openai)('s)?\s+opinion/i
                    ];
                    
                    const matchesAskPattern = askAnotherModelPatterns.some(pattern => 
                        latestUserMessage.match(pattern));
                    
                    if (matchesAskPattern) {
                        // Add a hint to Claude that it should use the ask_model function
                        enhancedMessage = latestUserMessage + 
                            "\n\nNote: When asked to consult another model, use the ask_model function directly rather than saying you will do so.";
                    }
                }
                
                // Format parameters for the CFC call
                const formData = new FormData();
                formData.append('method', 'sendMessage');
                formData.append('message', enhancedMessage);
                formData.append('model', model.name);
                formData.append('maxTokens', Number(1024).toString()); // Ensure it's sent as a string representation of a number
                formData.append('temperature', Number(0.7).toString()); // Ensure it's sent as a string representation of a number
                if (conversationId) {
                    formData.append('conversationId', conversationId);
                    console.log("Using existing conversationId for CFC call:", conversationId);
                } else {
                    console.log("No conversationId found, will create a new one");
                }
                
                // Log what we're sending
                console.log("Sending to CFC:", {
                    method: 'sendMessage',
                    message: enhancedMessage,
                    model: model.name,
                    maxTokens: 1024,
                    temperature: 0.7,
                    conversationId: conversationId || "(new)"
                });
                
                // Call the ColdFusion component
                console.log("Making CFC request to /cerberus/ClaudeCFC.cfc");
                const cfcResponse = await fetch('/cerberus/ClaudeCFC.cfc', {
                    method: 'POST',
                    body: formData
                });
                
                if (!cfcResponse.ok) {
                    const errorText = await cfcResponse.text();
                    throw new Error(`CFC request failed with status ${cfcResponse.status}: ${errorText}`);
                }
                
                // Process the response from the CFC
                // First check the content type of the response
                const contentType = cfcResponse.headers.get('content-type');
                let cfcResult;
                
                if (contentType && contentType.includes('application/json')) {
                    cfcResult = await cfcResponse.json();
                } else {
                    // Handle text response or other formats
                    const textResponse = await cfcResponse.text();
                    console.log("Raw CFC response:", textResponse);
                    
                    // Try to parse it as JSON anyway, it might be JSON with wrong content-type
                    try {
                        cfcResult = JSON.parse(textResponse);
                    } catch (e) {
                        // If not valid JSON, create a simple object with the text
                        cfcResult = {
                            text: textResponse,
                            conversationId: conversation.conversationId || ""
                        };
                    }
                }
                
                console.log("Processed CFC result:", cfcResult);
                
                // Debug: Log the CFC response structure
                console.log("CFC Response Structure:", JSON.stringify(cfcResult));
                
                // Store the conversation ID for future messages
                if (cfcResult.conversationId) {
                    conversation.conversationId = cfcResult.conversationId;
                    console.log("Found conversationId:", cfcResult.conversationId);
                }
                
                // Check if Claude's response mentions asking another model but doesn't use tool_use
                if (cfcResult.content && Array.isArray(cfcResult.content)) {
                    // Look for text content items
                    for (const item of cfcResult.content) {
                        if (item.type === 'text' && item.text) {
                            const text = item.text;
                            
                            // Check for phrases where Claude says it will ask another model
                            const willAskPatterns = [
                                /I('ll| will) ask (Grok|GPT|OpenAI)/i,
                                /Let me ask (Grok|GPT|OpenAI)/i,
                                /consulting (Grok|GPT|OpenAI)/i,
                                /I('ll| will) use the ask_model function/i,
                                /I('ll| can) consult with (Grok|GPT|OpenAI)/i
                            ];
                            
                            const matchesWillAsk = willAskPatterns.some(pattern => text.match(pattern));
                            
                            // If Claude says it will ask but doesn't use tool_use
                            if (matchesWillAsk && cfcResult.stop_reason !== 'tool_use') {
                                console.log("Claude said it would ask another model but didn't use tool_use");
                                // Add a note about this mismatch
                                if (!cfcResult.note) {
                                    cfcResult.note = "Claude mentioned asking another model but didn't use the ask_model function";
                                }
                            }
                        }
                    }
                }
                
                // Format the response to match the expected structure
                response = {
                    id: cfcResult.id || `claude-${Date.now()}`,
                    model: model.name,
                    conversationId: cfcResult.conversationId || conversation.conversationId
                };
                
                // Handle different response formats from CFC
                if (cfcResult.content && Array.isArray(cfcResult.content)) {
                    response.content = cfcResult.content;
                } else if (cfcResult.text) {
                    response.content = [{ type: 'text', text: cfcResult.text }];
                } else if (typeof cfcResult === 'string') {
                    response.content = [{ type: 'text', text: cfcResult }];
                } else if (cfcResult.message) {
                    response.content = [{ type: 'text', text: cfcResult.message }];
                } else {
                    // Default empty content
                    response.content = [{ type: 'text', text: 'No response content' }];
                }
                
                // If there was an error in the CFC response
                if (cfcResult.error) {
                    response.error = cfcResult.error;
                }
                
                // Pass along any notes
                if (cfcResult.note) {
                    response.note = cfcResult.note;
                }
                
                return response;
            } catch (error) {
                console.error(`Error calling Claude via CFC:`, error);
                return { error: error.message };
            }
        } else if (model.api_type === 'openai') {
            // Create headers for OpenAI
            const url = model.base_url + model.endpoint;
            const headers = {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${model.api_key}`
            };
            
            // Create a mapping between model keys and API model names
            const modelNameMapping = {
                'grok': 'grok-3-beta', 
                'claude': 'claude-opus-4-20250514',
                'openai': 'o4-mini'
            };
            
            // Exclude current model from enum to prevent self-querying
            const filteredEnum = ['grok-3-beta', 'claude-opus-4-20250514', 'o4-mini'].filter(name => name !== model.name);
            const customAskModelFunction = {
                name: 'ask_model',
                description: 'Ask a question to another AI model',
                parameters: {
                    type: 'object',
                    properties: {
                        query: { type: 'string', description: 'The question to ask' },
                        model_name: { type: 'string', description: 'The name of the model to ask', enum: filteredEnum }
                    },
                    required: ['query', 'model_name']
                }
            };
            
            const body = JSON.stringify({
                model: model.name,
                messages: conversation,
                functions: [customAskModelFunction],
                function_call: 'auto'
            });
            
            try {
                const response = await fetch(url, { 
                    method: 'POST', 
                    headers, 
                    body 
                });
                
                if (!response.ok) {
                    const errorText = await response.text();
                    throw new Error(`API request failed with status ${response.status}: ${errorText}`);
                }
                
                return await response.json();
            } catch (error) {
                console.error(`Error sending request to ${model.name}:`, error);
                return { error: error.message };
            }
        }
    }

    // **8. Handle Model Responses**
    async function handleModelResponse(modelKey, response, callDepth = 0, sourceModel = null) {
        const MAX_DEPTH = 3; // Increase from 1 to 3 to allow more complex interactions
        if (callDepth > MAX_DEPTH) {
            displayMessage(modelKey, 'ai', 'Error: Maximum function call depth exceeded. Conversation is too deep.');
            return;
        }
        
        if (response.error) {
            let errorMsg = '';
            if (typeof response.error === 'string') {
                errorMsg = response.error;
            } else if (response.error.message) {
                errorMsg = response.error.message;
            } else {
                errorMsg = JSON.stringify(response.error);
            }
            console.error("Error in model response:", response.error);
            displayMessage(modelKey, 'ai', `Error: ${errorMsg}`, sourceModel);
            return;
        }
        
        // Also handle case where response has type='error'
        if (response.type === 'error') {
            console.error("Error type in response:", response);
            let errorMsg = '';
            if (response.error && response.error.message) {
                errorMsg = response.error.message;
            } else {
                errorMsg = "An error occurred with the API request";
            }
            displayMessage(modelKey, 'ai', `Error: ${errorMsg}`, sourceModel);
            return;
        }
        
        const model = models[modelKey];
        
        if (isFunctionCall(response, model)) {
            const { function_name, function_args } = parseFunctionCall(response, model);
            displayMessage(modelKey, 'function', `${model.name} called ${function_name} with args: ${JSON.stringify(function_args)}`);
            
            try {
                // Get a friendly display name for the source model
                const sourceModelDisplay = modelKey === 'grok' ? 'Grok' : 
                                         modelKey === 'claude' ? 'Claude' : 
                                         modelKey === 'openai' ? 'GPT' : modelKey;
                
                // Get target model key from the function args
                const targetModelName = function_args.model_name;
                const targetModelKey = Object.keys(models).find(key => 
                    models[key].name === targetModelName);
                
                if (!targetModelKey) {
                    throw new Error(`Target model ${targetModelName} not found`);
                }
                
                // Display the query in the target model's conversation with a special class
                displayMessage(
                    targetModelKey, 
                    'model-query', 
                    function_args.query,
                    sourceModelDisplay
                );
                
                const functionResult = await executeFunction(function_name, function_args, modelKey);
                
                // Display the function result in the source model's conversation
                displayMessage(modelKey, 'function', `Function ${function_name} returned: ${functionResult}`);
                
                // Add an explicit system message instructing the model to not repeat the function call
                conversations[modelKey].push({
                    role: 'system',
                    content: "IMPORTANT SYSTEM INSTRUCTION: The ask_model function has just been used. DO NOT call the ask_model function again in your next response. Instead, directly incorporate the result below into your response to the user, and continue the conversation without making additional function calls."
                });
                
                // Handle function response based on API type
                if (model.api_type === 'openai') {
                    console.log("Adding function result to OpenAI conversation");
                    conversations[modelKey].push({ 
                        role: 'function', 
                        name: function_name, 
                        content: functionResult 
                    });
                    
                    // Add an extra assistant message to ensure the model sees the function result
                    conversations[modelKey].push({
                        role: 'assistant',
                        content: `I've received this response from ${function_args.model_name}: "${functionResult}". Let me provide my analysis based on this information.`
                    });
                } else if (model.api_type === 'anthropic') {
                    console.log("Adding function result to Claude conversation");
                    
                    // For Anthropic, handle differently based on whether we're using the proxy
                    if (conversations[modelKey].conversationId) {
                        // When using CFC proxy, add a simple format that will be handled by the proxy
                        // Format in a way the model clearly sees it as an external response
                        // For Claude, make sure to use the "Claude:" prefix so it knows to respond
                        const modelDisplayName = 
                            function_args.model_name === 'grok-3-beta' ? 'Grok' :
                            function_args.model_name === 'claude-opus-4-20250514' ? 'Claude' :
                            function_args.model_name === 'o4-mini' ? 'GPT' : function_args.model_name;
                           
                        // Extract the latest user message to check for recursive patterns
                        const latestUserMessage = [...conversations[modelKey]].reverse()
                            .find(msg => msg.role === 'user')?.content || '';
                            
                        // Add the response with very explicit formatting   
                        const formattedResponse = 
                            `Claude: Here is the exact response I received from ${modelDisplayName}:\n\n` +
                            `---BEGIN ${modelDisplayName} RESPONSE---\n` +
                            `${functionResult}\n` +
                            `---END ${modelDisplayName} RESPONSE---\n\n` +
                            `Please analyze this response and provide your insights. What do you find interesting or notable about ${modelDisplayName}'s answer?`;
                        
                        // Check if this is a response to a query that already came from analysis of another model
                        // This helps prevent infinite loops when models try to analyze responses that mention ask_model
                        const isRecursiveQuery = latestUserMessage && (
                            latestUserMessage.includes('analyze this response') || 
                            latestUserMessage.includes('analyze this information') ||
                            latestUserMessage.includes('analyze the response') ||
                            latestUserMessage.includes('analyze what') ||
                            latestUserMessage.includes('analyze GPT') ||
                            latestUserMessage.includes('analyze Claude') ||
                            latestUserMessage.includes('analyze Grok')
                        );
                        
                        if (isRecursiveQuery) {
                            // If this seems to be an analysis request, add a warning about not using ask_model again
                            conversations[modelKey].push({ 
                                role: 'user', 
                                content: formattedResponse + "\n\nIMPORTANT: Do not use ask_model in your response to this. Simply analyze the content directly."
                            });
                        } else {
                            conversations[modelKey].push({ 
                                role: 'user', 
                                content: formattedResponse
                            });
                        }
                        
                        // Also display this formatted response in the UI
                        displayMessage(
                            modelKey,
                            'function',
                            `Response received from ${modelDisplayName} and passed to Claude for analysis:\n${functionResult}`
                        );
                    } else {
                        // For direct API (not used currently), use the proper format
                        const toolUseId = Date.now().toString();
                        conversations[modelKey].push({ 
                            role: 'assistant', 
                            content: [
                                {
                                    type: 'tool_result',
                                    tool_use_id: toolUseId,
                                    tool_result: {
                                        content: functionResult
                                    }
                                }
                            ]
                        });
                    }
                    
                    // If we're using the CFC proxy, make sure the conversationId is preserved
                    if (conversations[modelKey].conversationId) {
                        console.log("Preserving conversationId:", conversations[modelKey].conversationId);
                    }
                }
                
                // Force a short delay to ensure the message is displayed before continuing
                await new Promise(resolve => setTimeout(resolve, 500));
                
                // Add user prompt to force the model to address the response directly
                const modelDisplayName = 
                    function_args.model_name === 'grok-3-beta' ? 'Grok' :
                    function_args.model_name === 'claude-opus-4-20250514' ? 'Claude' :
                    function_args.model_name === 'o4-mini' ? 'GPT' : function_args.model_name;
                    
                // Extract the latest user message to check for recursive patterns
                const latestUserMessage = [...conversations[modelKey]].reverse()
                    .find(msg => msg.role === 'user')?.content || '';
                
                // Create a more explicit message with the response clearly marked
                const modelPrefix = modelKey === 'grok' ? 'Grok' : modelKey === 'claude' ? 'Claude' : 'GPT';
                const formattedAnalysisRequest = 
                    `${modelPrefix}: Here is the exact response from ${modelDisplayName}:\n\n` +
                    `---BEGIN ${modelDisplayName} RESPONSE---\n` +
                    `${functionResult}\n` +
                    `---END ${modelDisplayName} RESPONSE---\n\n` +
                    `Please analyze this information and provide your insights. Do not make additional function calls or ask more questions.`;
                
                // Check if this is a response to a query that already came from analysis of another model
                const isRecursiveQuery = latestUserMessage && (
                    latestUserMessage.includes('analyze this response') || 
                    latestUserMessage.includes('analyze this information') ||
                    latestUserMessage.includes('analyze the response') ||
                    latestUserMessage.includes('analyze what') ||
                    latestUserMessage.includes('analyze GPT') ||
                    latestUserMessage.includes('analyze Claude') ||
                    latestUserMessage.includes('analyze Grok')
                );
                
                if (isRecursiveQuery) {
                    // If this seems to be an analysis request, add a warning about not using ask_model again
                    conversations[modelKey].push({ 
                        role: 'user', 
                        content: formattedAnalysisRequest + "\n\nIMPORTANT: Do not use ask_model in your response to this. Simply analyze the content directly."
                    });
                } else {
                    conversations[modelKey].push({
                        role: 'user',
                        content: formattedAnalysisRequest
                    });
                }
                
                const finalResponse = await sendRequest(model, conversations[modelKey]);
                
                // Stop function call processing for this chain to prevent any chance of looping
                const safeCallDepth = MAX_DEPTH - 1; // Force it to be just below the max, so no more functions get called
                handleModelResponse(modelKey, finalResponse, safeCallDepth);
            } catch (error) {
                displayMessage(modelKey, 'ai', `Error executing function: ${error.message}`, sourceModel);
            }
        } else {
            const aiResponse = getTextResponse(response, model);
            
            if (model.api_type === 'anthropic') {
                // For Anthropic, add the entire response content array
                conversations[modelKey].push({ 
                    role: 'assistant', 
                    content: response.content || [{ type: 'text', text: aiResponse }]
                });
            } else {
                conversations[modelKey].push({ 
                    role: 'assistant', 
                    content: aiResponse 
                });
            }
            
            displayMessage(modelKey, 'ai', aiResponse, sourceModel);
        }
    }

    // **9. Function Implementation**
    const appFunctions = {
        ask_model: async (args, sourceModelKey, sourceModelDisplay) => {
            console.log(`Ask model function called by ${sourceModelDisplay} with args:`, args);
            const { query, model_name } = args;
            
            // Find the matching model key - handle both display names and API names
            let targetModelKey;
            
            // First try direct match with model name (API format like 'grok-3-beta')
            targetModelKey = Object.keys(models).find(key => models[key].name === model_name);
            
            // If not found, try to match based on partial name (e.g. if 'grok' was specified instead of 'grok-3-beta')
            if (!targetModelKey) {
                const modelLower = model_name.toLowerCase();
                if (modelLower.includes('grok')) {
                    targetModelKey = 'grok';
                } else if (modelLower.includes('claude')) {
                    targetModelKey = 'claude';
                } else if (modelLower.includes('gpt') || modelLower.includes('openai')) {
                    targetModelKey = 'openai';
                }
            }
            
            console.log("Found target model key:", targetModelKey);
            
            if (targetModelKey) {
                console.log(`Sending query to ${models[targetModelKey].name}: "${query}"`);
                
                // Create a proper conversation history just for this query
                const tempConversation = [];
                
                // Add system message with limitations to prevent infinite loops
                // Mention which model is asking the question
                const systemInstruction = `Answer the following question from ${sourceModelDisplay} briefly and accurately. IMPORTANT: Do not use the ask_model function in your response. Do not refer to other models in your answer. Just answer the question directly.`;
                
                if (targetModelKey === 'grok') {
                    // Grok might need a more explicit instruction set for better results
                    tempConversation.push({ 
                        role: 'system', 
                        content: `You are Grok, an AI assistant created by xAI. ${systemInstruction} 
                        
You are being queried by ${sourceModelDisplay} through a function call. Keep your answers clear, informative, and to the point. DO NOT ask follow-up questions.` 
                    });
                } else if (targetModelKey === 'claude') {
                    tempConversation.push({ 
                        role: 'system', 
                        content: `You are Claude, an AI assistant created by Anthropic. ${systemInstruction} 
                        
You are being queried by ${sourceModelDisplay} through a function call. Keep your answers clear, informative, and to the point. DO NOT ask follow-up questions.` 
                    });
                } else if (targetModelKey === 'openai') {
                    tempConversation.push({ 
                        role: 'system', 
                        content: `You are o4-mini, an AI assistant created by OpenAI. ${systemInstruction}
                        
You are being queried by ${sourceModelDisplay} through a function call. Keep your answers clear, informative, and to the point. DO NOT ask follow-up questions.` 
                    });
                }
                
                // Add the user query with a prefix indicating which model is asking
                tempConversation.push({ 
                    role: 'user', 
                    content: `[Query from ${sourceModelDisplay}]: ${query}` 
                });
                
                // Send the request
                const response = await sendRequest(models[targetModelKey], tempConversation);
                
                // Display the response in the target model's conversation with source model info
                const targetModelDisplay = targetModelKey === 'grok' ? 'Grok' : 
                                         targetModelKey === 'claude' ? 'Claude' : 'GPT';
                
                const textResponse = getTextResponse(response, models[targetModelKey]) || 'Error: No response';
                
                // Display the response in the target model's conversation
                displayMessage(
                    targetModelKey, 
                    'ai', 
                    textResponse,
                    sourceModelDisplay
                );
                
                console.log(`Response from ${models[targetModelKey].name} to ${sourceModelDisplay}:`, textResponse);
                return textResponse;
            }
            return 'Error: Model not found. Please specify Grok, Claude, or GPT/OpenAI.';
        }
    };

    async function executeFunction(functionName, functionArgs, sourceModelKey) {
        if (appFunctions[functionName]) {
            try {
                // Get a friendly display name for the source model
                const sourceModelDisplay = sourceModelKey === 'grok' ? 'Grok' : 
                                         sourceModelKey === 'claude' ? 'Claude' : 
                                         sourceModelKey === 'openai' ? 'GPT' : sourceModelKey;
                                         
                // Pass the source model information to the function
                return await appFunctions[functionName](functionArgs, sourceModelKey, sourceModelDisplay);
            } catch (error) {
                return `Error: ${error.message}`;
            }
        }
        return 'Error: Function not found';
    }

    // **10. Helper Functions**
    function isFunctionCall(response, model) {
        console.log("Checking if response is a function call:", response);
        
        if (model.api_type === 'openai') {
            // For standard OpenAI function call format
            if (response.choices && 
                response.choices[0].message && 
                response.choices[0].message.function_call) {
                console.log("Found standard OpenAI function call", response.choices[0].message.function_call);
                return true;
            }
            
            // For Grok's text-based function call format (specifically for Grok using OpenAI API format)
            if (response.choices && 
                response.choices[0].message && 
                response.choices[0].message.content) {
                
                const content = response.choices[0].message.content;
                
                // Check for ask_model in text format
                if (typeof content === 'string' && 
                    (content.includes('<ask_model>') || 
                     content.includes('ask_model(') || 
                     content.match(/ask_model\s*\{\s*["']query["']/i))) {
                    
                    console.log("Found text-based function call in Grok response:", content);
                    return true;
                }
            }
        } else if (model.api_type === 'anthropic') {
            // Check if it's a direct Anthropic API response or from our CFC proxy
            if (response.content && Array.isArray(response.content)) {
                // Look for standard tool_use items
                const toolUseItem = response.content.find(item => item.type === 'tool_use');
                if (toolUseItem) {
                    console.log("Found tool_use in content array:", toolUseItem);
                    return true;
                }
                
                // Check for text responses where Claude says it will ask another model
                for (const item of response.content) {
                    if (item.type === 'text' && item.text) {
                        const text = item.text;
                        
                        // Check for phrases where Claude says it will ask another model
                        const willAskPatterns = [
                            /I('ll| will) ask (Grok|GPT|OpenAI)/i,
                            /Let me ask (Grok|GPT|OpenAI)/i,
                            /consulting (Grok|GPT|OpenAI)/i,
                            /I('ll| will) use the ask_model function to query (Grok|GPT|OpenAI) (?:about|for|regarding|concerning)\s+([^\.]+)/i,
                            /I('ll| will) use the ask_model function to query (Grok|GPT|OpenAI) (?:about|for|regarding|concerning)\s+([^\.]+)/i
                        ];
                        
                        if (willAskPatterns.some(pattern => text.match(pattern))) {
                            console.log("Found text where Claude says it will ask another model:", text);
                            // This is effectively a function call - Claude is trying to use ask_model
                            return true;
                        }
                    }
                }
            }
            
            // For CFC proxied responses with stop_reason
            if (response.stop_reason === 'tool_use') {
                console.log("Found stop_reason = tool_use:", response);
                return true;
            }
            
            // For CFC proxied responses, check for function calls in the CFC response format
            if (response.tool_use || (response.content && response.content.tool_use)) {
                console.log("Found tool_use in response:", response.tool_use || response.content.tool_use);
                return true;
            }
            
            // Check for notes that Claude mentioned asking another model
            if (response.note && response.note.includes("mentioned asking another model")) {
                console.log("Found note about Claude mentioning ask_model:", response.note);
                return true;
            }
        }
        
        console.log("Not a function call");
        return false;
    }

    function parseFunctionCall(response, model) {
        console.log("Parsing function call from response:", response);
        
        if (model.api_type === 'openai') {
            // Check for standard OpenAI function call format
            if (response.choices[0].message.function_call) {
                const functionCall = response.choices[0].message.function_call;
                return {
                    function_name: functionCall.name,
                    function_args: JSON.parse(functionCall.arguments)
                };
            }
            
            // Handle Grok's text-based function call format
            if (response.choices[0].message.content) {
                const content = response.choices[0].message.content;
                
                // Check for ask_model in <ask_model> tags format
                if (content.includes('<ask_model>')) {
                    try {
                        console.log("Parsing <ask_model> tag format");
                        const askModelTag = content.match(/<ask_model>(.*?)<\/ask_model>/s);
                        if (askModelTag && askModelTag[1]) {
                            // Extract function arguments in JSON format
                            const jsonArgsStr = askModelTag[1].trim();
                            const args = JSON.parse(jsonArgsStr);
                            console.log("Extracted ask_model args from tags:", args);
                            return {
                                function_name: 'ask_model',
                                function_args: args
                            };
                        }
                    } catch (e) {
                        console.error("Error parsing ask_model tag:", e);
                    }
                }
                
                // Check for ask_model as JSON-like inline format
                const askModelJsonMatch = content.match(/ask_model\s*\{\s*"query"\s*:\s*"([^"]+)"\s*,\s*"model_name"\s*:\s*"([^"]+)"\s*\}/);
                if (askModelJsonMatch) {
                    try {
                        console.log("Parsing inline JSON-like ask_model format");
                        return {
                            function_name: 'ask_model',
                            function_args: {
                                query: askModelJsonMatch[1],
                                model_name: askModelJsonMatch[2]
                            }
                        };
                    } catch (e) {
                        console.error("Error parsing inline ask_model format:", e);
                    }
                }
                
                // Fallback for any other format
                console.log("Using regex fallback to extract function call");
                // Extract any JSON-like structure following ask_model
                const askModelMatch = content.match(/ask_model.*?(\{.*?\})/s);
                if (askModelMatch && askModelMatch[1]) {
                    try {
                        // Try to clean up the extracted JSON-like string
                        let jsonStr = askModelMatch[1].replace(/'/g, '"').trim();
                        // Handle cases where JSON might be malformed
                        if (!jsonStr.startsWith('{')) jsonStr = '{' + jsonStr;
                        if (!jsonStr.endsWith('}')) jsonStr = jsonStr + '}';
                        
                        const args = JSON.parse(jsonStr);
                        console.log("Extracted ask_model args with regex:", args);
                        return {
                            function_name: 'ask_model',
                            function_args: args
                        };
                    } catch (e) {
                        console.error("Error parsing ask_model with regex:", e);
                        // Last resort - try to extract query and model name using more forgiving regex
                        const queryMatch = content.match(/query["']?\s*:\s*["']([^"']+)["']/);
                        const modelMatch = content.match(/model_name["']?\s*:\s*["']([^"']+)["']/);
                        
                        if (queryMatch && modelMatch) {
                            console.log("Extracted ask_model with fallback regex");
                            return {
                                function_name: 'ask_model',
                                function_args: {
                                    query: queryMatch[1],
                                    model_name: modelMatch[1]
                                }
                            };
                        }
                    }
                }
                
                // If all parsing attempts fail, create a generic query
                console.log("All parsing attempts failed, using generic args");
                return {
                    function_name: 'ask_model',
                    function_args: {
                        query: "The system couldn't properly parse your function call. Please respond to this generic query instead.",
                        model_name: "claude-opus-4-20250514" // Default to Claude as the safest option
                    }
                };
            }
        } else if (model.api_type === 'anthropic') {
            // Handle standard Anthropic API response with content array
            if (response.content && Array.isArray(response.content)) {
                // First check for proper tool_use format
                const toolUse = response.content.find(item => item.type === 'tool_use');
                if (toolUse) {
                    console.log("Found tool_use in content array, extracting:", toolUse);
                    return {
                        function_name: toolUse.name,
                        function_args: toolUse.input
                    };
                }
                
                // If no proper tool_use, check for text responses where Claude says it will ask another model
                for (const item of response.content) {
                    if (item.type === 'text' && item.text) {
                        const text = item.text;
                        
                        // Define regex patterns to extract model name and potential query
                        const askPatterns = [
                            {
                                pattern: /I('ll| will) ask (Grok|GPT|OpenAI) (?:about|for|regarding|concerning)\s+([^\.]+)/i,
                                modelGroup: 2,
                                queryGroup: 3
                            },
                            {
                                pattern: /Let me ask (Grok|GPT|OpenAI) (?:about|for|regarding|concerning)\s+([^\.]+)/i,
                                modelGroup: 1,
                                queryGroup: 2
                            },
                            {
                                pattern: /I('ll| will) consult with (Grok|GPT|OpenAI) (?:about|for|regarding|concerning)\s+([^\.]+)/i,
                                modelGroup: 2,
                                queryGroup: 3
                            },
                            {
                                pattern: /I('ll| will) use the ask_model function to query (Grok|GPT|OpenAI) (?:about|for|regarding|concerning)\s+([^\.]+)/i,
                                modelGroup: 2,
                                queryGroup: 3
                            }
                        ];
                        
                        // Try each pattern
                        for (const { pattern, modelGroup, queryGroup } of askPatterns) {
                            const match = text.match(pattern);
                            if (match) {
                                const modelName = match[modelGroup];
                                const query = match[queryGroup].trim();
                                
                                // Map the model name to its API name
                                let targetModelName;
                                if (modelName.toLowerCase() === 'grok') {
                                    targetModelName = 'grok-3-beta';
                                } else if (modelName.toLowerCase() === 'gpt' || modelName.toLowerCase() === 'openai') {
                                    targetModelName = 'o4-mini';
                                } else if (modelName.toLowerCase() === 'claude') {
                                    targetModelName = 'claude-opus-4-20250514';
                                }
                                
                                if (targetModelName) {
                                    console.log(`Found ask_model intent in text. Model: ${targetModelName}, Query: ${query}`);
                                    return {
                                        function_name: 'ask_model',
                                        function_args: {
                                            query: query || "What is your opinion on this topic?",
                                            model_name: targetModelName
                                        }
                                    };
                                }
                            }
                        }
                        
                        // If we couldn't extract a specific query but the model is mentioned
                        if (text.match(/I('ll| will) ask (Grok|GPT|OpenAI)/i) || 
                            text.match(/Let me ask (Grok|GPT|OpenAI)/i) ||
                            text.match(/consulting (Grok|GPT|OpenAI)/i)) {
                            
                            // Extract the model name
                            let match = text.match(/(Grok|GPT|OpenAI)/i);
                            if (match) {
                                const modelName = match[1];
                                
                                // Map the model name to its API name
                                let targetModelName;
                                if (modelName.toLowerCase() === 'grok') {
                                    targetModelName = 'grok-3-beta';
                                } else if (modelName.toLowerCase() === 'gpt' || modelName.toLowerCase() === 'openai') {
                                    targetModelName = 'o4-mini';
                                } else if (modelName.toLowerCase() === 'claude') {
                                    targetModelName = 'claude-opus-4-20250514';
                                }
                                
                                if (targetModelName) {
                                    // Extract a potential subject from the entire text
                                    let subject = "your opinion on this topic";
                                    
                                    // Look for words after "about" or "regarding"
                                    const subjectMatch = text.match(/(?:about|regarding|concerning|on)\s+([^\.]+)/i);
                                    if (subjectMatch) {
                                        subject = subjectMatch[1].trim();
                                    }
                                    
                                    console.log(`Constructing query for ${targetModelName} about: ${subject}`);
                                    return {
                                        function_name: 'ask_model',
                                        function_args: {
                                            query: `What do you think about ${subject}?`,
                                            model_name: targetModelName
                                        }
                                    };
                                }
                            }
                        }
                    }
                }
            }
            
            // Handle CFC proxy response with nested content array
            if (response.content && Array.isArray(response.content)) {
                for (const item of response.content) {
                    if (item.type === 'tool_use') {
                        console.log("Found tool_use item in content array:", item);
                        return {
                            function_name: item.name,
                            function_args: item.input
                        };
                    }
                }
            }
            
            // Handle direct tool_use property
            if (response.tool_use) {
                console.log("Found tool_use at top level:", response.tool_use);
                return {
                    function_name: response.tool_use.name,
                    function_args: response.tool_use.input
                };
            }
            
            // Check response note for auto-detected intent
            if (response.note && response.note.includes("mentioned asking another model")) {
                // Extract a potential model name from the response text
                let targetModelName = 'o4-mini'; // Default to GPT
                
                if (response.content && Array.isArray(response.content)) {
                    for (const item of response.content) {
                        if (item.type === 'text' && item.text) {
                            if (item.text.match(/grok/i)) {
                                targetModelName = 'grok-3-beta';
                                break;
                            } else if (item.text.match(/claude/i)) {
                                targetModelName = 'claude-opus-4-20250514';
                                break;
                            }
                        }
                    }
                }
                
                console.log(`Creating synthetic ask_model call for ${targetModelName}`);
                return {
                    function_name: 'ask_model',
                    function_args: {
                        query: "What is your opinion on this topic?",
                        model_name: targetModelName
                    }
                };
            }
            
            // Default fallback
            console.log("Using fallback parsing method for tool_use");
            
            // Look through the entire response object for any property that might contain tool_use data
            for (const key in response) {
                const value = response[key];
                
                if (key === 'content' && Array.isArray(value)) {
                    for (const item of value) {
                        if (item.type === 'tool_use') {
                            console.log("Found tool_use in content array:", item);
                            return {
                                function_name: item.name,
                                function_args: item.input
                            };
                        }
                    }
                }
            }
            
            console.warn("Could not find function call information in response");
            return {
                function_name: 'ask_model',
                function_args: {
                    query: "The system detected an intent to ask another model but couldn't determine the specific question. Please provide your perspective on this topic.",
                    model_name: 'o4-mini' // Default to GPT as the safest option
                }
            };
        }
    }

    function getTextResponse(response, model) {
        console.log("Getting text response from:", response);
        
        if (model.api_type === 'openai') {
            return response.choices && 
                   response.choices[0].message && 
                   response.choices[0].message.content || 'No content';
        } else if (model.api_type === 'anthropic') {
            // Get text content blocks from standard Anthropic API response
            if (response.content && Array.isArray(response.content)) {
                const textBlocks = response.content
                    .filter(item => item.type === 'text')
                    .map(item => item.text)
                    .join('\n');
                
                console.log("Extracted text blocks from content array:", textBlocks);
                return textBlocks || 'No content';
            }
            // Fallback if content is not in expected format
            else if (typeof response.text === 'string') {
                console.log("Using response.text:", response.text);
                return response.text;
            }
            // Another possible format from CFC
            else if (response.message) {
                console.log("Using response.message:", response.message);
                return response.message;
            }
            
            // Last resort: Try to extract any text from the response
            console.log("Trying to find any text content in the response");
            for (const key in response) {
                const value = response[key];
                if (typeof value === 'string' && value.length > 10) {
                    console.log(`Found potential text in response.${key}:`, value);
                    return value;
                } else if (typeof value === 'object' && value !== null) {
                    if (value.text && typeof value.text === 'string') {
                        console.log(`Found text in response.${key}.text:`, value.text);
                        return value.text;
                    }
                    if (value.content && Array.isArray(value.content)) {
                        const nestedTextBlocks = value.content
                            .filter(item => item.type === 'text')
                            .map(item => item.text)
                            .join('\n');
                            
                        if (nestedTextBlocks) {
                            console.log(`Found text blocks in response.${key}.content:`, nestedTextBlocks);
                            return nestedTextBlocks;
                        }
                    }
                }
            }
            
            return 'No content found in response';
        }
    }
});
    </script>
</body>
</html>