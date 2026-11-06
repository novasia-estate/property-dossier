# Property Dossier

An offline document-pack inspector for people handing property files from one team to another. It answers three concrete questions: **is a required file present and readable, have its bytes changed, and which revision is active?**

It does not read the contents of a contract, establish legal title, authenticate a signature or decide which documents a jurisdiction requires. Your team supplies its own checklist. No uploads, telemetry, API key, paid account or runtime gems.

## Five-minute example

Ruby 3.1 or later:

```sh
gem install property_dossier
property-dossier --manifest examples/manifest.json --root examples/documents --as-of 2026-11-06
property-dossier --manifest examples/manifest.json --root examples/documents --as-of 2026-11-06 --format html > review.html
```

The example intentionally includes a missing inspection report. Exit 1 and `missing_requirement` are expected. All sample documents are invented plain-text fixtures, never client or legal documents. Download the [source examples](https://github.com/novasia-estate/property-dossier/tree/main/examples) or use those included in the installed gem directory (`gem which property_dossier`).

For the library:

```ruby
require 'property_dossier'
manifest = PropertyDossier::Manifest.load('manifest.json')
report = PropertyDossier::Inspector.new(manifest, root: './documents', as_of: '2026-11-06').call
puts report.to_json
puts report.ok? # false if any error; warnings alone do not fail
```

## What an inspection catches

* Required document kinds with no usable active document.
* Missing, unreadable, empty or non-file paths.
* SHA-256 mismatches when an expected digest is supplied.
* Expired documents relative to an explicit date (expiry day itself is valid).
* Unresolved competing revisions and broken supersession references.
* Identical content under different names (warning).
* Paths that escape the root, including resolved symbolic links.

No automatic 'latest filename wins'. A readable replacement must explicitly supersede a lower revision of the same kind. A broken replacement is still reported and does not hide an otherwise usable prior file.

## A practical handover

1. Agree the required document kinds with the receiving professional.
2. Copy the documents into a dedicated local folder you trust.
3. Assign stable IDs, revisions and optional expiry dates in the manifest.
4. Record digests at the point you actually receive a file.
5. Run an inspection using a fixed date; resolve errors and review warnings.
6. Transfer the manifest and files using your organisation's approved channel.
7. Re-run at receipt. A matching digest establishes byte identity, not authenticity.

The tool never edits source documents, silently refreshes expiry dates or infers a country's legal requirements. Output includes document paths: treat reports as sensitive if paths reveal client information.

## Documentation

* [Manifest contract](docs/manifest.md)
* [Threat model and limits](docs/security.md)
* [Integration and exit statuses](docs/integration.md)
* [Changelog](CHANGELOG.md)

Run `ruby -Ilib test/test_property_dossier.rb`. The suite uses temporary synthetic files and exercises invalid revisions, traversal, symlink escapes, expiry, tampering and HTML escaping. Build with `gem build property_dossier.gemspec`.

## Maintainer

Developed by [NovAsia Estate](https://novasia.estate/), a publisher of property guides and research for Cambodia, Thailand and Bali. This general-purpose tool contains no market offers, legal rules or regional tax assumptions.

For the next JSON-schema validation step, see the separate [Property Schema Validator](https://github.com/novasia-estate/property-schema-validator). That tool checks records; this one checks a local document pack. MIT licensed. Reproducible bug reports without client files are welcome.
