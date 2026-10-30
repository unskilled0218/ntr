# Implementation

- [Changes](#changes)
- [Verification](#verification)
- [Limitations](#limitations)

## Changes

- Shortened the root and app READMEs and app feature and project-renaming introductions. Fixed the ordering of the live-sync table of contents.
- Preserved dedicated topic documents, historical release notes, and the detailed data-safety and release/recovery guidance. The server submodule was not changed.
- Updated the client patch version from `0.15.26` to `0.15.27` across existing mirrors because the implementation workflow requires a version update, even for this documentation-only task.
- App submodule commit: `4fc1a91`.

## Verification

- Checked relative links and anchors in five changed Markdown files, plus 30 inbound links from tracked current documentation. These local checks do not verify external sites or all historical archive links.
- `git diff --check` passed in the parent and app repositories.
- `npm test`: 45 files and 722 tests passed. `npm run build` passed.
- No commands or code examples were changed. No publication, recovery, or destructive operation was run.

## Limitations

- Server version `0.2.9`: read-only `git ls-remote` did not advertise `v0.2.9`; the unauthenticated release API returned HTTP 404. That response does not establish absence of a private or partial release. Release identity remains unknown, so the server README and documentation were left unchanged under the plan's gate. A separately approved release/version decision and sufficient read-only evidence are needed before making server documentation commits.
- Server offline release validation and Python release tests were not run because no server documentation or release configuration was changed. The detailed release and recovery sections were deliberately retained.
- No runtime behavior was changed or newly validated on devices. The existing held-Backspace review warning remains unresolved.
