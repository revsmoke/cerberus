component output="false" access="remote" {

   
    //for future use
    variables.models = {
        grok: {
            handle: 'grok',
            name: 'grok-3-beta', // Updated to Grok 3
            api_key: 'API_KEY_1',
            base_url: 'https://api.x.ai/v2',
            endpoint: '/chat/completions',
            api_type: 'openai',
            max_tokens: 1024,
            temperature: 0.7
        },
        claude: {
            handle: 'claude',
            name: 'claude-4-opus-20250606', // Updated to Claude 4 Opus
            api_key: 'API_KEY_2',
            base_url: 'https://api.anthropic.com/v1',
            endpoint: '/messages',
            api_type: 'anthropic',
            max_tokens: 1024,
            temperature: 0.7
        },
        openai: {
            handle: 'gpt',
            name: 'o4-mini', // Using latest OpenAI reasoning model
            api_key: 'API_KEY_3',
            base_url: 'https://api.openai.com/v1',
            endpoint: '/responses',
            api_type: 'openai',
            max_tokens: 1024,
            temperature: 0.7
        }
    };
     // Hardcode the API key and other variables
     variables.apiKey = variables.models.claude.api_key;
     variables.baseURL = variables.models.claude.base_url & variables.models.claude.endpoint;
     variables.defaultModel = variables.models.claude.name;
     variables.defaultModelHandle = variables.models.claude.handle;
    variables.uploadDir = expandPath("./uploads");
    if (!directoryExists(variables.uploadDir)) {
        directoryCreate(variables.uploadDir);
    }

    /**
     * Constructor function
     */
    public function init() {
        // Create upload directory if it doesn't exist
        if (!directoryExists(variables.uploadDir)) {
            directoryCreate(variables.uploadDir);
        }
        return this;
    }

    /**
     * Returns a struct describing the current API key's status
     */
    remote function getApiKeyStatus() {
        var isConfigured = ( len(variables.apiKey) > 0 );
        var isValid = ( isConfigured AND left(variables.apiKey, 6) == "sk-ant" );

        return {
            "configured" : isConfigured,
            "valid"      : isValid,
            "keyStart"   : ( isConfigured ? left(variables.apiKey, 10) & "..." : "" )
        };
    }

    /**
     * Re-initializes by calling init() again, then returns new key status
     */
    remote function reInit() {
        init();
        return getApiKeyStatus();
    }

    /**
     * Sends a text message to the Claude API
     */
    /**
 * Sends a message to the Claude API with conversation history support
 */
remote function sendMessage(
    required string message,
    string model = variables.defaultModel,
    array files = [],  // Array of file paths/info
    string conversationId = "",  // New parameter for conversation tracking
    numeric maxTokens = 1024,
    numeric temperature = 0.7
) returnFormat="json" {
    // Set JSON content type header
    cfheader(name="Content-Type", value="application/json");
    // Add this logging at the start of the function
    writeLog(
        text="Received message request: " & serializeJSON(arguments),
        type="information",
        file="ClaudeChat"
    );

    // Log form data
    writeLog(
        text="Raw form data: " & serializeJSON(FORM),
        type="information",
        file="ClaudeChat"
    );

    // Log files array
    writeLog(
        text="Files array before processing: " & serializeJSON(arguments.files),
        type="information",
        file="ClaudeChat"
    );

    // Initialize conversation if not provided
    if (len(arguments.conversationId) == 0) {
        arguments.conversationId = createUUID();
    }
    
    // Build the current message content array
    var currentContent = [];

    // Add any files to the content
    if (arrayLen(arguments.files)) {
        try {
            var filesArray = isJSON(arguments.files) ? 
                deserializeJSON(arguments.files) : 
                arguments.files;
                
            for (var file in filesArray) {
                if (fileExists(variables.uploadDir & "/" & file.serverFile)) {
                    var fileContent = fileReadBinary(variables.uploadDir & "/" & file.serverFile);
                    var base64Content = binaryEncode(fileContent, "base64");
                    
                    // Determine content type based on file extension
                    var fileExt = listLast(file.serverFile, ".");
                    var mediaType = "";
                    var contentType = "document"; // default to "document"
                    
                    switch (lcase(fileExt)) {
                        case "pdf":
                            mediaType = "application/pdf";
                            contentType = "document";
                            break;
                        case "jpg":
                        case "jpeg":
                            mediaType = "image/jpeg";
                            contentType = "image";
                            break;
                        case "png":
                            mediaType = "image/png";
                            contentType = "image";
                            break;
                        default:
                            mediaType = "application/octet-stream";
                            contentType = "document";
                    }
                    
                    currentContent.append({
                        "type": contentType,
                        "source": {
                            "type": "base64",
                            "media_type": mediaType,
                            "data": base64Content
                        }
                    });

                    // Inside the file processing loop:
                    writeLog(
                        text="File path check: " & serializeJSON({
                            fullPath: variables.uploadDir & "/" & file.serverFile,
                            serverFile: file.serverFile,
                            exists: fileExists(variables.uploadDir & "/" & file.serverFile),
                            uploadDir: variables.uploadDir,
                            fileContent: (fileExists(variables.uploadDir & "/" & file.serverFile)) ? "Found" : "Missing"
                        }),
                        type="information",
                        file="ClaudeChat"
                    );
                }
            }
        } catch (any e) {
            writeLog(text="Error processing files: " & e.message, type="error");
        }
    }

    // Add the text message
    currentContent.append({
        "type": "text",
        "text": arguments.message
    });

    // Get conversation history from database or session
    var conversationHistory = getConversationHistory(arguments.conversationId);
    
    // Build messages array for API call
    var messages = [];
    
    // Add past messages from history
    for (var item in conversationHistory) {
        messages.append({
            "role": item.role,
            "content": deserializeJSON(item.content)
        });
    }
    
    // Add current user message
    messages.append({
        "role": "user",
        "content": currentContent
    });

    // Define the ask_model tool
    var askModelTool = {
        "name": "ask_model",
        "description": "Ask a question to another AI model",
        "input_schema": {
            "type": "object",
            "properties": {
                "query": { "type": "string", "description": "The question to ask" },
                "model_name": { 
                    "type": "string", 
                    "description": "The name of the model to ask",
                    "enum": ["grok-3-beta", "claude-4-opus-20250606", "o4-mini"]
                }
            },
            "required": ["query", "model_name"]
        }
    };
    
    // Build the JSON string manually to ensure proper number formatting
    var manualJsonPayload = '{
        "model": "' & arguments.model & '",
        "max_tokens": 1024,
        "temperature": 0.7,
        "messages": ' & serializeJSON(messages) & ',
        "tools": [' & serializeJSON(askModelTool) & ']
    }';
    
    // Log the manually constructed JSON
    writeLog(
        text="Manually constructed JSON payload: " & manualJsonPayload,
        type="information",
        file="ClaudeChat"
    );

    try {
        var httpService = new http();
        httpService.setMethod("POST");
        httpService.setUrl(variables.baseURL);
        httpService.addParam(type="header", name="anthropic-version", value="2023-06-01");
        httpService.addParam(type="header", name="content-type", value="application/json");
        httpService.addParam(type="header", name="x-api-key", value=variables.apiKey);
        
        // Use the manually constructed JSON instead of serializeJSON(payload)
        httpService.addParam(type="body", value=manualJsonPayload);

        var apiResponse = httpService.send().getPrefix();

        // Log the raw response
        writeLog(
            text="Raw API Response: " & apiResponse.fileContent,
            type="information",
            file="ClaudeChat"
        );

        // Check if we got valid JSON back
        if (isJSON(apiResponse.fileContent)) {
            var responseData = deserializeJSON(apiResponse.fileContent);
            
            // Enhanced logging for debugging tool use
            writeLog(
                text="Response data structure: " & serializeJSON(responseData),
                type="information",
                file="ClaudeChat"
            );
            
            // Check if this is a tool_use response
            if (structKeyExists(responseData, "stop_reason") && responseData.stop_reason == "tool_use") {
                writeLog(
                    text="Detected tool_use stop_reason, making sure tool info is preserved",
                    type="information",
                    file="ClaudeChat"
                );
            }
            
            // Store the assistant's response in conversation history
            if (structKeyExists(responseData, "content") && arrayLen(responseData.content)) {
                // Extract text content from the response
                var assistantContent = [];
                
                // Check each item in content for tool_use
                var hasToolUse = false;
                for (var item in responseData.content) {
                    assistantContent.append(item);
                    
                    // Check if this is a tool_use content item
                    if (structKeyExists(item, "type") && item.type == "tool_use") {
                        hasToolUse = true;
                        writeLog(
                            text="Found tool_use in content: " & serializeJSON(item),
                            type="information",
                            file="ClaudeChat"
                        );
                    }
                }
                
                // Save to conversation history
                saveMessageToHistory(
                    conversationId = arguments.conversationId,
                    role = "assistant",
                    content = serializeJSON(assistantContent)
                );
            }
            
            // Add conversationId to the response
            responseData["conversationId"] = arguments.conversationId;
            
            return responseData;
        } else {
            writeLog(
                text="Invalid JSON response: " & apiResponse.fileContent,
                type="error",
                file="ClaudeChat"
            );
            return {
                "error": {
                    "message": "Invalid response from API",
                    "details": apiResponse.fileContent
                },
                "conversationId": arguments.conversationId
            };
        }
    } catch (any e) {
        writeLog(
            text="API call error: " & e.message & " - " & e.detail,
            type="error",
            file="ClaudeChat"
        );
        return {
            "error": {
                "message": "API call failed",
                "details": e.message
            },
            "conversationId": arguments.conversationId
        };
    }
}

/**
 * Retrieves conversation history from database
 * Implement this based on your storage mechanism
 */
private array function getConversationHistory(required string conversationId) {
    // Example implementation using a database
    try {
        var messages = queryExecute(
            "SELECT role, content, created_at 
             FROM conversation_messages 
             WHERE conversation_id = :conversationId
             ORDER BY created_at ASC",
            { conversationId = arguments.conversationId }
        );
        
        return messages;
    } catch (any e) {
        writeLog(
            text="Error retrieving conversation history: " & e.message,
            type="error",
            file="ClaudeChat"
        );
        return [];
    }
}

/**
 * Saves a message to the conversation history
 * Implement this based on your storage mechanism
 */
private void function saveMessageToHistory(
    required string conversationId,
    required string role,
    required string content
) {
    try {
        // Store the current user message in history
        queryExecute(
            "INSERT INTO conversation_messages 
             (conversation_id, role, content, created_at) 
             VALUES (:conversationId, :role, :content, :created_at)",
            { 
                conversationId = arguments.conversationId,
                role = arguments.role,
                content = arguments.content,
                created_at = now()
            }
        );
    } catch (any e) {
        writeLog(
            text="Error saving message to history: " & e.message,
            type="error",
            file="ClaudeChat"
        );
    }
}

    /**
     * A remote method to handle entire-file uploads (no chunking).
     * Includes security checks and file validation.
     */
    remote any function upload() returnFormat="json" {
        // Set JSON content type header
        cfheader(name="Content-Type", value="application/json");

        // Create a structure to hold response data
        var response = {
            status: 400,
            message: "Invalid request.",
            success: false
        };

        // Security settings (used both in single upload + chunk)
        var allowedExtensions = "jpg,jpeg,png,pdf,txt,rtf,gif,html,htm,mp4,mov,avi,wmv,mkv,webm,dwg,dxf,dwf,rvt,rfa,ifc,skp,3dm,stp,step,iges,igs,x_t,prt,sldprt,sldasm,catpart,catproduct";
        var maxFileSize = 1024 * 1024 * 2048; // 2GB

        try {
            // Validate request
            if (!structKeyExists(form, "files[]")) {
                response.status = 400;
                response.message = "No files were selected for upload.";
                cfheader(statuscode=response.status, statustext=response.message);
                return response;
            }

            // Retrieve or create fileGroupId
            var fileGroupId = "";
            if (!structKeyExists(form, "fileGroupId")) {
                fileGroupId = createUUID();
            } else {
                fileGroupId = form.fileGroupId;
            }

            // Create subdir for this group
            var groupDir = variables.uploadDir & "/" & fileGroupId;
            if (!directoryExists(groupDir)) {
                directoryCreate(groupDir);
            }

            // Upload the actual files to the groupDir (temp files)
            var savedFiles = fileUploadAll(
                destination = groupDir,
                onconflict = "makeunique"
            );

            // We'll store final file info in an array for consistent JSON
            var uploadedFileStructs = [];

            // Validate & rename
            for (var file in savedFiles) {
                var fileExtension = listLast(file.clientFile, ".");
                // Check extension
                if (!listFindNoCase(allowedExtensions, fileExtension)) {
                    fileDelete(file.serverDirectory & "/" & file.serverFile);
                    response.status = 415; // Unsupported Media Type
                    response.message = "Invalid file type: " & file.clientFile;
                    response.success = false;
                    cfheader(statuscode=response.status, statustext=response.message);
                    return response;
                }

                var fileInfo = getFileInfo(file.serverDirectory & "/" & file.serverFile);
                var fileSize = fileInfo.size;

                // Check file size
                if (fileSize > maxFileSize) {
                    fileDelete(file.serverDirectory & "/" & file.serverFile);
                    response.status = 413; // Payload Too Large
                    response.message = "File size exceeds limit: " & file.clientFile;
                    response.success = false;
                    cfheader(statuscode=response.status, statustext=response.message);
                    return response;
                }

                // Build final path
                var fileId = hash(createUUID() & fileGroupId);
                var finalName = fileId & "_" & file.clientFile;
                var finalPath = variables.uploadDir & "/" & finalName;

                // Move from groupDir => final location
                fileMove(file.serverDirectory & "/" & file.serverFile, finalPath);

                // Build an entry that matches the chunk approach
                uploadedFileStructs.append({
                    "clientFile": file.clientFile,
                    "serverFile": finalName,
                    "fileSize": fileSize,
                    "mediaType": file.contentType
                });
            }

            // Success response
            response.status        = 200;
            response.message       = "Files uploaded successfully";
            response.files         = uploadedFileStructs;
            response.fileGroupId   = fileGroupId;
            response.success       = true;

        } catch (any e) {
            // Handle unexpected errors
            response.status = 500;
            response.message = "An error occurred while uploading files: " & e.message;
            response.success = false;
            // Log the error
            cflog(
                text="Upload Error: #e.message# #e.detail#",
                type="error",
                file="upload_errors"
            );
        }

        // In upload function, right before returning response:
        writeLog(
            text="Upload response: " & serializeJSON(response),
            type="information",
            file="ClaudeChat"
        );

        cfheader(statuscode=response.status, statustext=response.message);
        return response;
    }

    /**
     * A remote method to handle chunked file uploads.
     * On the final chunk, combine, then do the same checks & final naming
     * as the `upload()` method.
     */
    remote function uploadChunk() returnFormat="json" {
        cfheader(name="Content-Type", value="application/json");

        // Security settings
        var allowedExtensions = "jpg,jpeg,png,pdf,txt,rtf,gif,html,htm,mp4,mov,avi,wmv,mkv,webm,dwg,dxf,dwf,rvt,rfa,ifc,skp,3dm,stp,step,iges,igs,x_t,prt,sldprt,sldasm,catpart,catproduct";
        var maxFileSize = 1024 * 1024 * 2048; // 2GB

        // Default response struct
        var response = {
            status: 400,
            message: "Invalid request.",
            success: false
        };

        try {
            // Basic form fields
            if (!structKeyExists(form, "fileName")) {
                throw("Missing fileName in form data.");
            }
            var fileName   = form.fileName;
            var fileIndex  = val(form.fileIndex);
            var chunkIndex = val(form.chunkIndex);
            var totalChunks= val(form.totalChunks);

            // Must have a fileGroupId for chunk sessions
            if (!structKeyExists(form, "fileGroupId")) {
                throw("Upload session not found. No fileGroupId provided.");
            }
            var fileGroupId = form.fileGroupId;

            // We'll keep a subdir for partial chunks. 
            // This subdir is inside the main group folder:
            var groupDir = variables.uploadDir & "/" & fileGroupId;
            if (!directoryExists(groupDir)) {
                directoryCreate(groupDir);
            }

            // Use a unique ID for this one file name + index
            var fileId = hash(fileName & fileIndex & fileGroupId);
            var tempDir = groupDir & "/temp_" & fileId;

            // On first chunk, create temp dir; if it exists, nuke it
            if (chunkIndex == 0) {
                if (directoryExists(tempDir)) {
                    directoryDelete(tempDir, true);
                }
                directoryCreate(tempDir);

                // We can also track partial size in a small text file if needed
                fileWrite(tempDir & "/partial_size.txt", "0");
            } else if (!directoryExists(tempDir)) {
                throw("Upload session not found. Temp directory missing. Please restart upload.");
            }

            // Write the chunk
            // form.chunk must contain the chunk content
            fileWrite(tempDir & "/" & chunkIndex & ".chunk", fileReadBinary(form.chunk));
            var fileInfo = getFileInfo(form.chunk);
            var fileSize = fileInfo.size;

            // Update partial size
            var partialSizeFile = tempDir & "/partial_size.txt";
            var oldSize = val(fileRead(partialSizeFile));
            
            var newSize = oldSize + fileSize;
            fileWrite(partialSizeFile, newSize);

            // If not last chunk, done for now
            if (chunkIndex < totalChunks - 1) {
                response.status = 206; // Partial
                response.message= "Chunk ##" & chunkIndex & " uploaded.";
                response.success= true;
                response.chunkIndex = chunkIndex;
                cfheader(statuscode=response.status, statustext=response.message);
                return response;
            }

            // If we reach here, chunkIndex == totalChunks - 1 => time to combine
            var finalFileId = hash(createUUID() & fileGroupId);
            var finalName   = finalFileId & "_" & fileName;
            var finalPath   = variables.uploadDir & "/" & finalName;

            // Create the final file
            fileWrite(finalPath, "");

            // Append each chunk to the final file
            for (var i = 0; i < totalChunks; i++) {
                var chunkContent = fileReadBinary(tempDir & "/" & i & ".chunk");
                var finalFile = fileOpen(finalPath, "append");
                try {
                    fileWrite(finalFile, chunkContent);
                } finally {
                    fileClose(finalFile);
                }
            }

            // Now we do the *same validation checks* as in `upload()`:
            // 1) Check extension
            var fileExtension = listLast(fileName, ".");
            if (!listFindNoCase(allowedExtensions, fileExtension)) {
                // Delete the final file
                if (fileExists(finalPath)) {
                    fileDelete(finalPath);
                }
                // Clean up
                if (directoryExists(tempDir)) {
                    directoryDelete(tempDir, true);
                }
                response.status = 415;
                response.message = "Invalid file type: " & fileName;
                response.success = false;
                cfheader(statuscode=response.status, statustext=response.message);
                return response;
            }

            // 2) Check total size
            var totalSize = val(fileRead(partialSizeFile));
            if (totalSize > maxFileSize) {
                // Delete the final file
                if (fileExists(finalPath)) {
                    fileDelete(finalPath);
                }
                // Clean up
                if (directoryExists(tempDir)) {
                    directoryDelete(tempDir, true);
                }
                response.status = 413;
                response.message= "File size exceeds the allowed limit: " & fileName;
                response.success= false;
                cfheader(statuscode=response.status, statustext=response.message);
                return response;
            }

            // If everything is OK, remove temp dir
            directoryDelete(tempDir, true);

            // Build final JSON: same as in single‐shot
            response.status      = 200;
            response.message     = "File uploaded successfully via chunking.";
            response.success     = true;
            response.fileGroupId = fileGroupId;
            response.files       = [
                {
                    "clientFile": fileName,
                    "serverFile": finalName,
                    "fileSize": totalSize,
                    "mediaType": getMimeType(fileExtension)
                }
            ];

            // If you want to store any extra form data:
            // saveFormData(fileName, FORM);

        } catch (any e) {
            // Something failed
            response.status = 500;
            response.message = "Chunked upload error: " & e.message;
            response.success = false;
            cflog(
                text="Chunk Upload Error: #e.message# #e.detail#",
                type="error",
                file="upload_errors"
            );
        }

        // In upload function, right before returning response:
        writeLog(
            text="Upload response: " & serializeJSON(response),
            type="information",
            file="ClaudeChat"
        );

        cfheader(statuscode=response.status, statustext=response.message);
        return response;
    }

    /**
     * Example: store form data to a database
     * (unused in this snippet, but you could call it if needed)
     */
    private function saveFormData(required string fileName, required struct formScope) {
        var formData = duplicate(formScope);
        formData.fileName = fileName;
        formData.uploadDate = now();
        // Implement your data storage logic here
        // Example:
        // queryExecute("
        //   INSERT INTO uploads (fileName, uploadDate, otherField)
        //   VALUES (:fileName, :uploadDate, :otherField)",
        //   {fileName=formData.fileName, uploadDate=formData.uploadDate, otherField="someVal"}
        // );
    }

    remote function resetApp() returnFormat="json" {
        try {
            // Delete all files in uploads directory
            var uploadDir = expandPath("./uploads");
            if (directoryExists(uploadDir)) {
                directoryDelete(uploadDir, true);
                directoryCreate(uploadDir);
            }
            
            return {
                "success": true,
                "message": "App reset successfully"
            };
        } catch (any e) {
            return {
                "success": false,
                "message": "Error resetting app: " & e.message
            };
        }
    }

    private string function getMimeType(required string ext) {
        switch(lcase(ext)) {
            case "jpg":
            case "jpeg":
                return "image/jpeg";
            case "png":
                return "image/png";
            case "pdf":
                return "application/pdf";
            default:
                return "application/octet-stream";
        }
    }

    /**
     * Minimal Agent2Agent endpoint.
     * Accepts JSON payload with fields `model` and `message` and
     * returns the model response. This is a simplified demonstration
     * of the A2A protocol for agent communication.
     */
    remote function a2a() returnFormat="json" {
        var raw = toString(getPageContext().getRequest().getInputStream());
        var data = isJSON(raw) ? deserializeJSON(raw) : {};
        if (!structKeyExists(data, "model") || !structKeyExists(data, "message")) {
            cfheader(statuscode=400, statustext="Bad Request");
            return {error: "Missing model or message"};
        }
        var result = sendMessage(
            message = data.message,
            model = data.model
        );
        return result;
    }

}