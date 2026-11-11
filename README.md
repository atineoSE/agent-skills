# Agent Skills

A personal collection of agent skills for [Claude Code](https://claude.com/claude-code)
and [OpenHands](https://github.com/All-Hands-AI/OpenHands).

Each skill lives in its own directory under `Claude/` or `OpenHands/`, described by a
`SKILL.md` with frontmatter that tells the agent when to load it. Some carry supporting
scripts or reference files alongside.

To use one with Claude Code, copy or symlink its directory into `~/.claude/skills/`
(user-wide) or `.claude/skills/` (per project).

## Third-party skills

`Claude/animate` uses six Framer Motion skills (`framer-motion-core`, `-gestures`,
`-layout`, `-react`, `-scroll`, `-variants`). They come from
[C-Jeril/framer-motion-skills](https://github.com/C-Jeril/framer-motion-skills) (MIT).
They are not in this repo: `.gitignore` excludes them. To get them, run this from the
repo root:

```bash
git clone --depth 1 https://github.com/C-Jeril/framer-motion-skills /tmp/fms
cp -R /tmp/fms/skills/framer-motion-* Claude/
```

## License

Copyright (C) 2026 Adrian Tineo.

Licensed under the GNU General Public License, version 3 or later. See [LICENSE](LICENSE).
