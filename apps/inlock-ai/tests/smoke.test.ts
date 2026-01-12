import { expect, describe, it } from "vitest";
import { getBlogPostBySlug } from "../src/lib/blog";
import { loadMarkdown } from "../src/utils/markdown";

describe("content sanity", () => {
  it("has markdown for the default blog post", () => {
    const meta = getBlogPostBySlug("local-vs-cloud-ai");
    expect(meta).toBeTruthy();
    const md = loadMarkdown(meta!.file);
    expect(md.length).toBeGreaterThan(20);
    expect(md).toMatch(/local vs cloud ai/i);
  });
});

