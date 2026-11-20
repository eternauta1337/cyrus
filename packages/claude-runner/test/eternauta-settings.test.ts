// Tests for the eternauta fork switch of Claude settings sources.
import { afterEach, describe, expect, it, vi } from "vitest";
import { claudeSettingSources } from "../src/eternauta-settings.js";

afterEach(() => {
	vi.unstubAllEnvs();
});

describe("eternauta: CYRUS_CLAUDE_SIN_USER_SETTINGS", () => {
	it("skips the user's settings when the variable is 1", () => {
		vi.stubEnv("CYRUS_CLAUDE_SIN_USER_SETTINGS", "1");
		expect(claudeSettingSources()).toEqual(["project", "local"]);
	});

	it("loads user, project and local otherwise, like upstream", () => {
		vi.stubEnv("CYRUS_CLAUDE_SIN_USER_SETTINGS", "");
		expect(claudeSettingSources()).toEqual(["user", "project", "local"]);
	});
});
