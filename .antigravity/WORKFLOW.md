# Maintenance Workflow

1) Keep paths current
- Update `antigravity.md` and `antigravity-manifest.json` when repo paths or layout change.

2) Keep rules aligned
- Ensure `antigravity-rules.md` matches `/home/comzis/.cursor/projects/home-comzis-inlock/.cursorrules`.

3) Validate
- Validate JSON syntax after edits:
  `python3 -m json.tool antigravity-manifest.json > /dev/null`

4) Test
- Run a small Antigravity dry run and confirm scope is correct.
