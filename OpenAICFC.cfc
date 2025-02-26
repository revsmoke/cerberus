<cfcomponent 
    displayname="ChatAPI" 
    hint="Chat-based CFC that replicates the Flask/OpenAI logic" 
    rest="true" 
    restPath="/ChatAPI">
    
    <!---
        Use system environment variables (similar to os.environ in Python).
        CFML provides getSystemSetting() for that purpose.
    --->
    <cfscript>
    this.apiKey         = getSystemSetting("OPENAI_API_KEY", "");
    this.sessionSecret  = getSystemSetting("SESSION_SECRET", "");
    this.allowedExtensions = ["txt","pdf","png","jpg","jpeg","gif"];
    </cfscript>

    <!--- 
        Equivalent of the Flask root endpoint:
        Renders 'index.html' when a user accesses GET /.
     --->
    <cffunction 
        name="index" 
        access="remote" 
        returntype="any" 
        httpMethod="GET" 
        restPath="/">
        <cfscript>
        // Read index.html (adjust path as necessary)
        var indexContent = fileRead(expandPath("../index.html"));
        // Return the raw HTML so the client can render it
        return indexContent;
        </cfscript>
    </cffunction>

    <!--- 
        Equivalent of the Flask /chat POST endpoint:
        Reads JSON input, calls OpenAI's Chat Completion, and returns JSON.
     --->
    <cffunction 
        name="chat" 
        access="remote" 
        returntype="any" 
        httpMethod="POST" 
        restPath="/chat">
        <cfscript>
        try {
            // Grab raw request body & parse JSON
            var rawInput   = toString(getPageContext().getRequest().getInputStream());
            var requestData = deserializeJSON(rawInput);

            var message   = requestData.message;
            var username  = requestData.username;
            var history   = requestData.keyExists("history") ? requestData.history : [];

            // Ensure a message was actually sent
            if (!len(message)) {
                cfheader(statusCode=400, statusText="Bad Request");
                return {
                    "error" : "Message is required"
                };
            }

            // Build the messages array for the OpenAI API call
            var messages = [
                {
                    "role"    = "system",
                    "content" = "You are having a conversation with #username#. Be friendly and helpful. Talk like a hollywood pirate"
                }
            ];

            // Append any conversation history the user sent
            if (isArray(history)) {
                // Just push them into the messages array in order
                for (var i = 1; i <= arrayLen(history); i++) {
                    arrayAppend(messages, history[i]);
                }
            }

            // Prepare the data for the Chat Completion endpoint
            var payload = {
                "model"    = "gpt-4o",
                "messages" = messages
            };

            // Make the request to OpenAI
            http url="https://api.openai.com/v1/chat/completions"
                 method="post"
                 result="local.openAIResponse"
                 charset="utf-8">
                <cfhttpparam type="header" name="Authorization" value="Bearer #this.apiKey#">
                <cfhttpparam type="header" name="Content-Type"  value="application/json">
                <cfhttpparam type="body"   value="#serializeJSON(payload)#">
            </http>

            // Check the response
            if (local.openAIResponse.statusCode eq 200) {
                var responseData = deserializeJSON(local.openAIResponse.fileContent);
                var aiMessage    = responseData.choices[1].message.content; 
                // NOTE: Sometimes indexing is 1-based or 0-based, depending on the API response.
                // If you get an error, check whether it should be choices[1] or choices[0].

                return {
                    "response" : aiMessage
                };
            } else {
                // The call failed; return the error
                cfheader(statusCode=500, statusText="Internal Server Error");
                return {
                    "error" : local.openAIResponse.statusCode & ": " & local.openAIResponse.fileContent
                };
            }

        } catch (any e) {
            // Catch any error
            cfheader(statusCode=500, statusText="Internal Server Error");
            return {
                "error" : e.message
            };
        }
        </cfscript>
    </cffunction>
    <cffunction name="upload" access="remote" returntype="any" httpMethod="POST" restPath="/upload">
        <cfscript>
          try {
            var fileData = getHttpRequestData().fileContent;
            // CF automatically puts form fields into "form" scope for multipart/form-data
            var username   = form.username;
            // Do your file handling, e.g.:
            //   cffile action="upload" filefield="file" destination="/some/upload/folder"
            //   Or in CFScript style, see <cffile> doc
            
            // Return a JSON response (example)
            return {
              "response" = "Arr, yer file be processed! Me found: " & form.file
            };
          } catch (any e) {
            cfheader(statusCode=500, statusText="Internal Server Error");
            return {
              "error" = e.message
            };
          }
        </cfscript>
      </cffunction>
</cfcomponent>