# frozen_string_literal: true
module PropertyDossier
  # Strict, portable manifest. File names refer to a local root, never remote URLs.
  class Manifest
    class Invalid < StandardError; end
    attr_reader :property_id, :requirements, :documents

    def self.load(path)
      new(JSON.parse(File.read(path, encoding: 'UTF-8')))
    rescue JSON::ParserError => e
      raise Invalid, "Invalid JSON: #{e.message}"
    end

    def initialize(data)
      fail!('manifest must be an object') unless data.is_a?(Hash)
      fail!('schema_version must be 1') unless data['schema_version'] == 1
      @property_id = text!(data['property_id'], 'property_id')
      @requirements = data.fetch('requirements', [])
      fail!('requirements must be unique strings') unless @requirements.is_a?(Array) && @requirements.all? { |r| r.is_a?(String) && !r.strip.empty? } && @requirements.uniq == @requirements
      @documents = data['documents']
      fail!('documents must be an array') unless @documents.is_a?(Array)
      ids = []
      paths = []
      @documents.each do |d|
        fail!('each document must be an object') unless d.is_a?(Hash)
        id = text!(d['id'], 'document.id')
        fail!("duplicate document id: #{id}") if ids.include?(id)
        ids << id
        text!(d['kind'], "#{id}.kind")
        path = text!(d['path'], "#{id}.path")
        fail!("unsafe path: #{path}") if path.include?('\\') || path.include?(':') || path.start_with?('/') || path.split('/').any? { |p| p.empty? || ['.', '..'].include?(p) }
        fail!("duplicate document path: #{path}") if paths.include?(path)
        paths << path
        revision = d['revision']
        fail!("#{id}.revision must be a positive integer") unless revision.is_a?(Integer) && revision.positive?
        fail!("#{id}.sha256 must be lowercase hex") if d.key?('sha256') && !(d['sha256'].is_a?(String) && d['sha256'].match?(/\A[0-9a-f]{64}\z/))
        fail!("#{id}.supersedes must reference a different document") if d.key?('supersedes') && (!d['supersedes'].is_a?(String) || d['supersedes'] == id)
        next unless d.key?('expires_on')
        value = d['expires_on']
        begin
          fail!("#{id}.expires_on must be YYYY-MM-DD") unless value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          Date.iso8601(value)
        rescue Date::Error
          fail!("#{id}.expires_on is not a calendar date")
        end
      end
      @documents.each do |d|
        next unless d['supersedes']
        prior = @documents.find { |p| p['id'] == d['supersedes'] }
        fail!("unknown superseded document: #{d['supersedes']}") unless prior
        fail!('supersession must preserve kind and increase revision') unless prior['kind'] == d['kind'] && prior['revision'] < d['revision']
      end
    end

    private
    def fail!(message)
      raise Invalid, message
    end
    def text!(value, field)
      fail!("#{field} must be nonempty text") unless value.is_a?(String) && !value.strip.empty?
      value
    end
  end
end
