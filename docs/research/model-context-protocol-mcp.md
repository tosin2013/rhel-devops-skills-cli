# Model Context Protocol (MCP)

**Date**: 2026-03-31
**Category**: standards-research
**Status**: Complete

## Research Question

What is MCP, how does it differ from Agent Skills, and when should it be used instead of or alongside SKILL.md-based skills?

## Background

The PRD references MCP without clearly distinguishing it from the skill system. Claude Desktop uses MCP servers for extension; Claude Code and Cursor use SKILL.md. This research clarifies the relationship and recommends when to use each.

## Methodology

- Reviewed the official MCP specification at modelcontextprotocol.io
- Reviewed MCP tool and resource specifications
- Reviewed Claude Desktop and Claude Code MCP configuration guides
- Analyzed the architectural differences between MCP and Agent Skills

## Key Findings

### Finding 1: MCP Is an Open Standard for AI-Tool Integration
- **Description**: Model Context Protocol (MCP) is an open standard created by Anthropic (released late 2024) that enables LLM applications to connect to external tools, databases, and APIs via a standardized JSON-RPC 2.0 protocol. As of 2026, it is the de facto standard for tool integration in AI agents.
- **Evidence**: Official specification published at modelcontextprotocol.io
- **Confidence**: High
- **Source**: [MCP Specification](https://modelcontextprotocol.io/specification/latest)

### Finding 2: MCP Exposes Three Capability Types
- **Description**: MCP servers expose:
  1. **Tools**: Functions the model can call (e.g., search_web, query_database)
  2. **Resources**: Read-only structured data (e.g., file contents, DB records)
  3. **Prompts**: Reusable prompt templates for standardized tasks
- **Evidence**: Specified in the MCP server capabilities spec
- **Confidence**: High
- **Source**: [MCP Tools](https://modelcontextprotocol.io/specification/latest/server/tools), [MCP Resources](https://modelcontextprotocol.io/specification/latest/server/resources)

### Finding 3: MCP Transport Options
- **Description**: MCP servers communicate via two transport methods:
  - **stdio**: Local subprocess communication (zero network overhead, best for local tools)
  - **SSE/HTTP**: Server-Sent Events over HTTP (for remote/multi-user deployments)
- **Evidence**: Specification defines both transport protocols
- **Confidence**: High
- **Source**: [MCP Specification](https://modelcontextprotocol.io/specification/latest)

### Finding 4: Claude Desktop Uses MCP for Extension
- **Description**: Claude Desktop (the standalone app) extends via MCP servers configured in `claude_desktop_config.json`:
  - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
  - **Linux**: `~/.config/claude/claude_desktop_config.json`
  - **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
  Claude Desktop does NOT have a native skills directory; MCP is the only extension mechanism.
- **Evidence**: Official configuration documentation
- **Confidence**: High
- **Source**: [MCP Installation Guide](https://www.claudeskillshq.com/blog/mcp-installation-deep-dive-claude-code-desktop)

### Finding 5: MCP vs Agent Skills Are Complementary
- **Description**: MCP and Agent Skills serve different purposes:
  - **Agent Skills** (SKILL.md): Static knowledge, instructions, workflows, documentation references. No runtime required.
  - **MCP Servers**: Dynamic tools, live data access, API integration. Requires a running server process.
  For the rhel-devops-skills-cli use case (providing documentation and workflow guidance), Agent Skills are the appropriate mechanism. MCP would be appropriate if the skills needed to execute live tools (e.g., running ansible-navigator, querying APIs).
- **Evidence**: Skills are file-based; MCP requires server processes
- **Confidence**: High
- **Source**: [Claude Code MCP](https://docs.claude.com/en/docs/claude-code/mcp), [Agent Skills Spec](https://agentskills.io/specification)

### Finding 6: MCP Registry (Preview)
- **Description**: An MCP Registry is in preview at modelcontextprotocol.io/registry, providing a centralized metadata repository for publicly accessible MCP servers. This could be relevant for future distribution of skills as MCP servers.
- **Evidence**: Registry documented as preview feature
- **Confidence**: Medium
- **Source**: [MCP Registry](https://modelcontextprotocol.io/registry)

## Implications

### Architectural Impact
- The primary use case (providing documentation and workflow guidance) is best served by Agent Skills (SKILL.md), not MCP servers
- MCP support for Claude Desktop should be considered a future enhancement, not a primary target
- If the project later needs live tool execution (e.g., running validation scripts, fetching live repo data), MCP servers would be the right approach

### Technology Choices
- Primary: Agent Skills (SKILL.md) for documentation and instructions
- Future: MCP servers (Python with `mcp` SDK) for live tool integration
- Config format: JSON for MCP server registration in claude_desktop_config.json

### Risk Assessment
- **Low risk**: Choosing Agent Skills for initial release (simpler, no runtime dependency)
- **Medium risk**: Deferring MCP support excludes Claude Desktop users initially
- **Low risk**: MCP can be added later without breaking existing skills

## Recommendations

1. Use Agent Skills (SKILL.md) as the primary delivery mechanism
2. Defer MCP server packaging to a future release
3. If Claude Desktop support is critical, create a lightweight MCP server that exposes documentation as Resources
4. Document the MCP vs Skills distinction in user-facing docs
5. Monitor the MCP Registry for potential distribution channel

## Related ADRs

- ADR-002: Target Claude Code + Cursor
- ADR-003: Documentation Embedding Strategy

## References

- [MCP Specification (latest)](https://modelcontextprotocol.io/specification/latest)
- [MCP Tools Specification](https://modelcontextprotocol.io/specification/latest/server/tools)
- [MCP Resources Specification](https://modelcontextprotocol.io/specification/latest/server/resources)
- [MCP Registry (preview)](https://modelcontextprotocol.io/registry)
- [Claude Code MCP Documentation](https://docs.claude.com/en/docs/claude-code/mcp)
- [MCP Installation Guide for Claude](https://www.claudeskillshq.com/blog/mcp-installation-deep-dive-claude-code-desktop)
- [MCP: The Tool Ecosystem for AI Agents](https://dev.to/neo_one_944288aac0bb5e89b/model-context-protocol-mcp-the-tool-ecosystem-for-ai-agents-24mi)
- [Complete Guide to Building Skills for Claude 2026](https://mcpdirectory.app/blog/complete-guide-building-skills-for-claude-mcp-2026)
