# AI & Integration Standards

How we integrate AI capabilities (Claude, MCP servers, LLMs) into Power Platform and .NET solutions.

---

## When to Use AI

| Good fit | Poor fit |
|---|---|
| Natural-language search over docs | Math computation (use code) |
| Document classification / summarization | Deterministic business rules (use Power Fx / C#) |
| Drafting content for human review | Final decisions on financial transactions |
| Data extraction from unstructured input | High-volume real-time decisions (latency + cost) |
| Conversational interfaces | Things a SQL query can answer |

If you can solve it with deterministic code, do that. AI is the right answer when the input is unstructured or the rule space is huge.

---

## Architecture Pattern: AI Middleware

```
┌──────────────┐      ┌──────────────────┐      ┌───────────┐
│  Power App   │─────▶│  AI Middleware   │─────▶│  Claude   │
│  / Power     │      │  (.NET API)      │      │  Anthropic│
│  Automate    │      │                  │      └───────────┘
└──────────────┘      │  - Auth          │
                      │  - Caching       │      ┌───────────┐
                      │  - Rate limit    │─────▶│ Other LLM │
                      │  - Telemetry     │      └───────────┘
                      │  - Redaction     │
                      └──────────────────┘
```

**Never** call Claude/OpenAI directly from a Canvas App — always go through middleware.

Why:
- Centralized auth, rate limiting, caching
- PII redaction before model calls
- Switch model providers without changing the app
- Audit log of every AI interaction

---

## .NET AI Middleware Standards

### Use the Anthropic SDK

```csharp
// Install: dotnet add package Anthropic.SDK

var client = new AnthropicClient(builder.Configuration["Anthropic:ApiKey"]);
```

Use Claude **Opus 4.7** (`claude-opus-4-7`) for complex reasoning, **Sonnet 4.6** (`claude-sonnet-4-6`) for balanced workloads, **Haiku 4.5** (`claude-haiku-4-5-20251001`) for high-volume / low-latency.

### Always enable prompt caching

For any prompt with reused content > 1024 tokens, mark it as cached:

```csharp
new MessageRequest
{
    Model = "claude-opus-4-7",
    MaxTokens = 1024,
    System = new List<SystemMessage>
    {
        new()
        {
            Type = "text",
            Text = systemPromptText,
            CacheControl = new CacheControl { Type = "ephemeral" }
        }
    },
    Messages = userMessages
}
```

Caching reduces cost ~90% on cache hits and improves latency.

### Telemetry per call

Log:
- `model` used
- `inputTokens`, `outputTokens`, `cacheReadTokens`, `cacheWriteTokens`
- `durationMs`
- `success` / `errorCode`
- Hashed prompt fingerprint (for cache analytics)

Never log the prompt or response content unless explicitly approved (PII risk).

### Redaction before model calls

Before sending user content to the model:
- Strip emails, phone numbers, credit cards (or replace with placeholders)
- Strip Dataverse internal IDs (replace with friendly labels)
- Apply org's DLP rules

---

## MCP (Model Context Protocol) Servers

We use MCP servers to expose tools/data to Claude in a standardized way.

### When to build an MCP server
- You want Claude Code (or any MCP client) to read/write your system
- You have a data source not yet covered by an off-the-shelf MCP server
- The integration is reusable across multiple agents

### MCP server structure

```
mcp-servers/<name>/
├── src/
│   ├── server.ts          # Or server.cs for .NET
│   ├── tools/             # One file per tool
│   └── resources/         # Read-only data
├── README.md
└── package.json (or .csproj)
```

### Tools vs Resources

| Concept | When |
|---|---|
| **Tool** | Action with side effects (`create_asset`, `send_email`) |
| **Resource** | Read-only data the agent can browse (`docs://asset-policy`) |

### MCP server checklist
- [ ] All tools have JSON Schema input definitions
- [ ] All tools have a clear `description` (the agent reads it)
- [ ] Auth handled at the server layer (not per tool)
- [ ] Rate limiting per client
- [ ] Telemetry on every tool call

---

## Prompt Engineering Conventions

For prompts that ship in code:

### Structure

```
1. Role / persona
2. Task description
3. Constraints + format requirements
4. Examples (few-shot if needed)
5. The actual user input
```

### Where prompts live
- Static prompts → in `templates/dotnet/AIMiddleware/Prompts/*.md`
- Dynamic prompts → composed at runtime, but built from versioned templates
- Never inline a long prompt as a string literal — load from a `.md` file

### Versioning prompts
Each prompt file has a version header:

```markdown
---
id: asset-summarizer
version: 2
purpose: Summarize an asset record into a 2-sentence description
---
You are an enterprise asset analyst...
```

When you change a prompt, bump the version and keep the old version available for rollback.

---

## Cost & Rate Controls

- Set per-user and per-tenant rate limits in middleware
- Set monthly $ cap per environment (alert at 80%)
- Cache common queries (Redis or in-memory) — TTL appropriate for use case
- Use Haiku for first-pass; only escalate to Opus when needed

---

## Evaluation

Maintain a regression suite for every prompt:

```
tests/AIMiddleware.Tests/
└── Prompts/
    ├── asset-summarizer.cases.json   ← input/expected output pairs
    └── PromptEvaluation.cs           ← runs the cases, scores outputs
```

Score with deterministic checks where possible (regex, JSON schema). Use Claude as a judge for subjective quality.

Run on every prompt change.

---

## When To Use Claude Agent SDK vs the API directly

| Use the **Claude Agent SDK** when... | Use the **API directly** when... |
|---|---|
| You need filesystem, bash, or web tools out of the box | You're building a single-turn endpoint |
| You're orchestrating long-running tasks | You want minimal dependencies |
| You want to reuse Claude Code's primitives | You don't need agentic behavior |

---

## Reference

- [Anthropic API docs](https://docs.anthropic.com)
- [MCP specification](https://modelcontextprotocol.io)
- [Claude Agent SDK](https://docs.claude.com/en/api/agent-sdk)
