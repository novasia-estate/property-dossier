# Manifest v1

The manifest is UTF-8 JSON with `schema_version: 1`, a nonempty `property_id`, unique `requirements` document-kind strings and a `documents` array. Requirements are supplied by the user and are not a statutory checklist.

Each document needs `id`, `kind`, forward-slash relative `path`, and positive integer `revision`. Optional fields: `sha256` (64 lowercase hexadecimal characters), `expires_on` (strict YYYY-MM-DD calendar date), `supersedes` (another document ID of the same kind with a lower revision). IDs and paths are unique. Unknown fields are retained in the report for your own descriptive metadata; do not put secrets there.

Absolute paths, backslashes, drive letters, empty segments, `.` and `..` segments are rejected. The inspector resolves file paths and rejects escapes through symbolic links. Files should remain immutable while inspection runs.

A supersession chain must increase revision numbers. This also prevents cycles. Multiple unrelated active documents of one kind produce an error even if revision numbers differ. Split document kinds when several distinct files are genuinely required (for example `floor_plan` and `site_plan`).

Errors prevent a clean report. Duplicate bytes are warnings because a legitimate translation placeholder or duplicate receipt may need human review rather than automatic rejection. Dates are evaluated as calendar dates; the tool does not infer time zones or statutory grace periods.
