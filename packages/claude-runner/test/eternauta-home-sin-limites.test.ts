// Tests for the eternauta fork opt-out of home directory restrictions.
import { homedir } from "node:os";
import { join } from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import { buildHomeDirectoryDisallowedTools } from "../src/home-directory-restrictions.js";

afterEach(() => {
	vi.unstubAllEnvs();
});

describe("eternauta: CYRUS_HOME_SIN_LIMITES", () => {
	const cwd = join(homedir(), ".cyrus", "worktrees", "X-1");

	it("returns no restrictions when the variable is 1", () => {
		vi.stubEnv("CYRUS_HOME_SIN_LIMITES", "1");
		expect(buildHomeDirectoryDisallowedTools(cwd)).toEqual([]);
	});

	it("keeps the default behavior for any other value", () => {
		vi.stubEnv("CYRUS_HOME_SIN_LIMITES", "0");
		expect(buildHomeDirectoryDisallowedTools(cwd).length).toBeGreaterThan(0);
	});
});
