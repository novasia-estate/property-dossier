# frozen_string_literal: true
require 'cgi'
module PropertyDossier
  class Report
    attr_reader :data
    def initialize(property_id, as_of, documents, findings)
      @data = { 'schema_version' => 1, 'property_id' => property_id, 'as_of' => as_of,
                'ok' => findings.none? { |f| f['severity'] == 'error' },
                'documents' => documents, 'findings' => findings }
    end
    def ok? = @data['ok']
    def to_json(*) = JSON.pretty_generate(@data)
    def to_html
      esc = ->(s) { CGI.escapeHTML(s.to_s) }
      rows = @data['findings'].map { |f| '<tr>' + %w[severity code subject message].map { |k| "<td>#{esc.call(f[k])}</td>" }.join + '</tr>' }.join
      "<!doctype html><html lang=\"en\"><meta charset=\"utf-8\"><title>Dossier inspection</title><style>body{font:16px system-ui;max-width:1100px;margin:3rem auto;padding:1rem}td,th{padding:.6rem;border:1px solid #ccc;text-align:left}table{border-collapse:collapse}code{overflow-wrap:anywhere}</style><h1>#{esc.call(@data['property_id'])}</h1><p>As of #{esc.call(@data['as_of'])}: #{ok? ? 'PASS' : 'REVIEW REQUIRED'}</p><p>File completeness and integrity only. This report does not authenticate documents or certify ownership.</p><table><tr><th>Severity</th><th>Code</th><th>Subject</th><th>Explanation</th></tr>#{rows}</table><h2>Machine-readable report</h2><pre><code>#{esc.call(to_json)}</code></pre></html>"
    end
  end
end
