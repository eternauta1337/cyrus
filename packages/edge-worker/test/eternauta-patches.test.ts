// Tests for the eternauta fork patches in edge-worker.
import { describe, expect, it } from "vitest";
import { AgentSessionManager } from "../src/AgentSessionManager";
import { EdgeWorker } from "../src/EdgeWorker";
import { UserAccessControl } from "../src/UserAccessControl";

describe("eternauta: stale stop flag is cleared on resume (cyrusagents/cyrus#1389)", () => {
	const ID = "session-stopped";

	async function resumeAfterStop(agentRunner: unknown): Promise<boolean> {
		const manager = new AgentSessionManager();
		manager.requestSessionStop(ID);
		// `this` has no logger, so resumeAgentSession throws right after the patch.
		await (EdgeWorker.prototype as any).resumeAgentSession
			.call({}, { agentRunner }, {}, ID, manager, "continue")
			.catch(() => {});
		return (manager as any).stopRequestedSessions.has(ID);
	}

	it("clears the flag when the stopped runner is already dead", async () => {
		expect(await resumeAfterStop({ isRunning: () => false })).toBe(false);
	});

	it("clears the flag when there is no runner", async () => {
		expect(await resumeAfterStop(undefined)).toBe(false);
	});

	it("keeps the flag while the runner is still alive", async () => {
		expect(await resumeAfterStop({ isRunning: () => true })).toBe(true);
	});
});

describe("eternauta: access check uses the message author on prompted webhooks", () => {
	const ALLOWED = "0a19139f-7bb3-4eca-afda-999eca6ecca3";
	const OTHER = "11111111-2222-3333-4444-555555555555";
	const REPO = { id: "repo-1" } as any;
	const control = new UserAccessControl(
		undefined,
		new Map([[REPO.id, { allowedUsers: [{ id: ALLOWED }] }]]) as any,
	);
	const check = (webhook: unknown) =>
		(EdgeWorker.prototype as any).checkUserAccess.call(
			{ userAccessControl: control },
			webhook,
			REPO,
		);
	const orphan = { id: "s1", creator: undefined };

	it("allows an allowed author in a session with no creator", () => {
		expect(
			check({ agentSession: orphan, agentActivity: { userId: ALLOWED } }),
		).toEqual({ allowed: true });
	});

	it("blocks a non-allowed author in a session with no creator", () => {
		expect(
			check({ agentSession: orphan, agentActivity: { userId: OTHER } }).allowed,
		).toBe(false);
	});

	it("falls back to the creator when the session is created", () => {
		expect(
			check({ agentSession: { id: "s2", creator: { id: ALLOWED } } }),
		).toEqual({ allowed: true });
		expect(
			check({ agentSession: { id: "s3", creator: { id: OTHER } } }).allowed,
		).toBe(false);
	});
});
