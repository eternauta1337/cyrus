// Tests for the eternauta fork CYRUS_CONTEXT_FILE.
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import {
	RunnerConfigBuilder,
	readContextFile,
} from "../src/RunnerConfigBuilder";

afterEach(() => {
	vi.unstubAllEnvs();
});

function contextFile(text: string): string {
	const path = join(mkdtempSync(join(tmpdir(), "ctx-")), "context.md");
	writeFileSync(path, text);
	return path;
}

const build = (custom?: string) =>
	(
		new (RunnerConfigBuilder as any)(
			undefined,
			undefined,
			undefined,
			() => custom,
		) as any
	).withCustomInstructions("BASE");

describe("eternauta: CYRUS_CONTEXT_FILE", () => {
	it("adds nothing without the variable", () => {
		vi.stubEnv("CYRUS_CONTEXT_FILE", "");
		expect(readContextFile()).toBeUndefined();
		expect(build()).toBe("BASE");
	});

	it("adds nothing when the file is missing", () => {
		vi.stubEnv("CYRUS_CONTEXT_FILE", "/nonexistent/context.md");
		expect(build()).toBe("BASE");
	});

	it("appends the file after the system prompt", () => {
		vi.stubEnv("CYRUS_CONTEXT_FILE", contextFile("# Team context\n"));
		expect(build()).toBe("BASE\n\n# Team context");
	});

	it("keeps the hosted custom instructions before the file", () => {
		vi.stubEnv("CYRUS_CONTEXT_FILE", contextFile("CTX"));
		expect(build("Be brief.")).toBe(
			"BASE\n\n## Custom instructions\n\nBe brief.\n\nCTX",
		);
	});

	it("reads the file again on every session", () => {
		const path = contextFile("one");
		vi.stubEnv("CYRUS_CONTEXT_FILE", path);
		expect(build()).toBe("BASE\n\none");
		writeFileSync(path, "two");
		expect(build()).toBe("BASE\n\ntwo");
	});
});
