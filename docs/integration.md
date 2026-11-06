# Integration

CLI exit statuses: 0 = no errors; 1 = inspection completed with findings requiring review; 2 = invocation, manifest or root error. Warnings alone leave exit status 0. JSON includes schema version, explicit inspection date, property ID, original document metadata, computed hashes, usability and machine-readable finding codes.

Redirect standard output to keep reports. Errors in invocation go to standard error. HTML is a standalone human-readable rendering of the same report. There is no automatic reporting upload.

For CI, keep fixtures synthetic and run with a fixed date. An optional checksum is meaningful only if recorded through a trustworthy receipt process. To create one locally: `ruby -rdigest -e 'puts Digest::SHA256.file(ARGV[0]).hexdigest' path/to/file`.
