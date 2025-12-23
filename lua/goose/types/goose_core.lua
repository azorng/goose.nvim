---@class GooseMessageMetadata
---@field userVisible boolean
---@field agentVisible boolean

---@class GooseTextContent
---@field type "text"
---@field text string

---@class GooseImageContent
---@field type "image"
---@field data string
---@field mimeType string

---@class GooseToolCallArguments
---@field command string|nil
---@field path string|nil
---@field name string|nil
---@field task_parameters table|string|nil

---@class GooseToolCallValue
---@field name string
---@field arguments GooseToolCallArguments

---@class GooseToolCall
---@field status "success"|"error"
---@field value GooseToolCallValue|nil
---@field error string|nil

---@class GooseToolRequest
---@field type "toolRequest"
---@field id string
---@field toolCall GooseToolCall

---@class GooseToolResponse
---@field type "toolResponse"
---@field id string
---@field toolResult table

---@alias GooseMessageContent GooseTextContent|GooseImageContent|GooseToolRequest|GooseToolResponse|table

---@class GooseMessage
---@field id string|nil
---@field role "user"|"assistant"
---@field created number?
---@field content GooseMessageContent[]
---@field metadata GooseMessageMetadata?

---@class GooseSession
---@field conversation GooseMessage[]

---@class GooseStreamOutput
---@field type "message"|"complete"
---@field message GooseMessage
---@field total_tokens number|nil
