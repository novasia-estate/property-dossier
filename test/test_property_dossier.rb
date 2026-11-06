# frozen_string_literal: true
require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../lib/property_dossier'

class DossierTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    File.write(File.join(@dir, 'title.txt'), 'synthetic title fixture')
    @doc = { 'id' => 'title-1', 'kind' => 'title', 'path' => 'title.txt', 'revision' => 1 }
  end
  def teardown = FileUtils.remove_entry(@dir)
  def manifest(docs = [@doc], requirements = ['title'])
    PropertyDossier::Manifest.new('schema_version' => 1, 'property_id' => 'DEMO-UNIT', 'requirements' => requirements, 'documents' => docs)
  end
  def inspect_docs(docs = [@doc], requirements = ['title'])
    PropertyDossier::Inspector.new(manifest(docs, requirements), root: @dir, as_of: '2026-11-06').call
  end
  def codes(report) = report.data['findings'].map { |f| f['code'] }
  def test_complete_pack
    assert inspect_docs.ok?
    assert_equal Digest::SHA256.hexdigest('synthetic title fixture'), inspect_docs.data['documents'][0]['actual_sha256']
  end
  def test_missing_file_does_not_satisfy_requirement
    @doc['path'] = 'absent.pdf'
    assert_equal %w[missing_file missing_requirement], codes(inspect_docs)
  end
  def test_checksum_mismatch
    @doc['sha256'] = '0' * 64
    assert_includes codes(inspect_docs), 'checksum_mismatch'
    refute inspect_docs.ok?
  end
  def test_expiry_boundary
    @doc['expires_on'] = '2026-11-06'
    assert inspect_docs.ok?
    @doc['expires_on'] = '2026-11-05'
    assert_includes codes(inspect_docs), 'expired'
  end
  def test_empty_file
    File.write(File.join(@dir, 'title.txt'), '')
    assert_includes codes(inspect_docs), 'empty_file'
  end
  def test_path_traversal
    ['../private.txt', '/etc/passwd', 'C:/secret', 'folder\\secret', './title.txt', 'x//y'].each do |path|
      assert_raises(PropertyDossier::Manifest::Invalid) { manifest([@doc.merge('path' => path)]) }
    end
  end
  def test_invalid_manifest_types_and_dates
    [nil, [], {}, {'schema_version' => 2}].each { |v| assert_raises(PropertyDossier::Manifest::Invalid) { PropertyDossier::Manifest.new(v) } }
    ['2026-02-30', '26-11-06', 123].each { |d| assert_raises(PropertyDossier::Manifest::Invalid) { manifest([@doc.merge('expires_on' => d)]) } }
  end
  def test_duplicate_ids_and_paths
    assert_raises(PropertyDossier::Manifest::Invalid) { manifest([@doc, @doc]) }
    assert_raises(PropertyDossier::Manifest::Invalid) { manifest([@doc, @doc.merge('id' => 'other')]) }
  end
  def test_conflicting_versions
    File.write(File.join(@dir, 'new.txt'), 'second version')
    newer = @doc.merge('id' => 'title-2', 'path' => 'new.txt', 'revision' => 2)
    assert_includes codes(inspect_docs([@doc, newer])), 'unresolved_versions'
    assert inspect_docs([@doc, newer.merge('supersedes' => 'title-1')]).ok?
  end
  def test_broken_replacement_does_not_hide_existing_valid_document
    newer = @doc.merge('id' => 'title-2', 'path' => 'missing.txt', 'revision' => 2, 'supersedes' => 'title-1')
    refute_includes codes(inspect_docs([@doc, newer])), 'missing_requirement'
  end
  def test_invalid_revision_chain
    assert_raises(PropertyDossier::Manifest::Invalid) { manifest([@doc.merge('supersedes' => 'unknown')]) }
    newer = @doc.merge('id' => 'title-2', 'path' => 'new.txt', 'supersedes' => 'title-1')
    assert_raises(PropertyDossier::Manifest::Invalid) { manifest([@doc, newer]) }
  end
  def test_duplicate_content_warning
    FileUtils.cp(File.join(@dir, 'title.txt'), File.join(@dir, 'copy.txt'))
    report = inspect_docs([@doc, @doc.merge('id' => 'translation', 'kind' => 'translation', 'path' => 'copy.txt')])
    assert report.ok?
    assert_includes codes(report), 'duplicate_content'
  end
  def test_directory_not_a_document
    Dir.mkdir(File.join(@dir, 'directory'))
    assert_includes codes(inspect_docs([@doc.merge('path' => 'directory')])), 'not_a_file'
  end
  def test_html_escapes_untrusted_text
    report = PropertyDossier::Report.new('<script>alert(1)</script>', '2026-11-06', [], [])
    refute_includes report.to_html, '<script>'
    assert_includes report.to_html, '&lt;script&gt;'
  end
  def test_symlink_outside_root
    Dir.mktmpdir do |outside|
      File.write(File.join(outside, 'secret.txt'), 'not a dossier file')
      begin
        File.symlink(File.join(outside, 'secret.txt'), File.join(@dir, 'link.txt'))
      rescue NotImplementedError, Errno::EACCES
        skip 'symlink privileges unavailable'
      end
      report = inspect_docs([@doc.merge('path' => 'link.txt')])
      assert_includes codes(report), 'outside_root'
      assert_nil report.data['documents'][0]['actual_sha256']
    end
  end
end
