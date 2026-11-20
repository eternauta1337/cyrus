/**
 * eternauta: which Claude Code settings sources a session loads.
 *
 * Upstream always loads ["user", "project", "local"]. With
 * CYRUS_CLAUDE_SIN_USER_SETTINGS=1 the user's own settings (plugins, MCP
 * servers, permissions in ~/.claude) are skipped, while the Claude credential
 * still works. For runners that share a machine account with a person.
 */
export function claudeSettingSources(): ("user" | "project" | "local")[] {
	return process.env.CYRUS_CLAUDE_SIN_USER_SETTINGS === "1"
		? ["project", "local"]
		: ["user", "project", "local"];
}
