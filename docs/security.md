# Security boundary

Run only on a dedicated folder and manifest you are authorised to inspect. The program does not execute files, extract archives, parse PDFs, fetch URLs, send telemetry or modify documents. HTML reports escape text and include no external scripts or resources.

File hashes attest only to bytes observed locally. A forged document can have a valid checksum. File existence, expiry metadata and a complete checklist do not establish legal validity, signer identity, ownership, availability or freedom from encumbrances.

The root folder must not be changed by an untrusted concurrent process. Path resolution followed by file reading is not an operating-system sandbox and does not protect against hostile races. Special files are rejected; a large ordinary file may still take time to hash. Reports disclose names, manifest metadata and hashes; keep them under the same access controls as the pack. Do not upload client files in bug reports.
