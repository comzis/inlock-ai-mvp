import fs from "fs";
import path from "path";

export function loadMarkdown(file: string): string {
  const fullPath = path.join(process.cwd(), "content", file);
  const fileContent = fs.readFileSync(fullPath, "utf8");
  return fileContent.replace(/^---[\s\S]*?---\n/, "");
}
