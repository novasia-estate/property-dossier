# frozen_string_literal: true
module PropertyDossier
  class Inspector
    def initialize(manifest, root:, as_of:)
      @manifest = manifest
      @root = File.realpath(root)
      raise ArgumentError, 'root must be a directory' unless File.directory?(@root)
      @as_of = Date.iso8601(as_of)
      @findings = []
    end

    def call
      @findings = []
      rows = @manifest.documents.map { |d| inspect_document(d) }
      superseded = @manifest.documents.filter_map { |d| d['supersedes'] if rows.find { |r| r['id'] == d['id'] }['usable'] }
      active = rows.select { |r| r['usable'] && !superseded.include?(r['id']) }
      @manifest.requirements.each do |kind|
        finding('missing_requirement', kind, 'No readable, current, checksum-valid active document satisfies this kind.') unless active.any? { |r| r['kind'] == kind }
      end
      active.group_by { |r| r['kind'] }.each do |kind, group|
        finding('unresolved_versions', kind, 'Several active documents exist; explicitly supersede older versions.') if group.size > 1
      end
      rows.select { |r| r['actual_sha256'] }.group_by { |r| r['actual_sha256'] }.each_value do |group|
        finding('duplicate_content', group.map { |r| r['id'] }.join(', '), 'Identical bytes are referenced more than once.', 'warning') if group.size > 1
      end
      Report.new(@manifest.property_id, @as_of.iso8601, rows, @findings)
    end

    private
    def inspect_document(doc)
      row = doc.merge('usable' => false)
      path = File.join(@root, doc['path'])
      unless File.exist?(path)
        finding('missing_file', doc['id'], 'File does not exist.'); return row
      end
      resolved = File.realpath(path)
      root_path = Pathname.new(@root)
      relative = Pathname.new(resolved).relative_path_from(root_path).to_s
      if relative == '..' || relative.start_with?("..#{File::SEPARATOR}") || Pathname.new(relative).absolute?
        finding('outside_root', doc['id'], 'Resolved path escapes the dossier root.'); return row
      end
      unless File.file?(resolved)
        finding('not_a_file', doc['id'], 'Path is not a regular file.'); return row
      end
      row['bytes'] = File.size(resolved)
      row['actual_sha256'] = Digest::SHA256.file(resolved).hexdigest
      valid = true
      if row['bytes'].zero?
        finding('empty_file', doc['id'], 'Empty documents do not satisfy requirements.'); valid = false
      end
      if doc['sha256'] && doc['sha256'] != row['actual_sha256']
        finding('checksum_mismatch', doc['id'], 'Bytes differ from the manifest checksum.'); valid = false
      end
      if doc['expires_on'] && Date.iso8601(doc['expires_on']) < @as_of
        finding('expired', doc['id'], 'Document expiry precedes the explicit inspection date.'); valid = false
      end
      row['usable'] = valid
      row
    rescue SystemCallError, ArgumentError => e
      finding('unreadable', doc['id'], e.message); row
    end

    def finding(code, subject, message, severity = 'error')
      @findings << { 'code' => code, 'subject' => subject, 'severity' => severity, 'message' => message }
    end
  end
end
