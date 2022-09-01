# frozen_string_literal: true

require 'open3'
require 'bundler/setup'
require 'zfs/snap'
require 'English'

$script_dir = File.expand_path(File.dirname(__FILE__))

class TestData < Hash
  # DEFAULT_MOUNTPOINTS is a list of ZFS filesystem mountpoints for
  # datasets that can be (possibly created and) safely deleted. They are
  # used for snapshot testing. The mountpoints are expected to be of the
  # format:
  #   /parent1/child1, /parent1/child2, ...
  #   /parent2/child1, /parent2/child2, ...
  #
  DEFAULT_MOUNTPOINTS = %w[/zfs-snap/test1 /zfs-snap/test2 /zfs-snap/test3].freeze

  DF_PATH = case RbConfig::CONFIG['host_os']
            when /linux/, /freebsd/
              '/bin/df'
            when /solaris/
              '/usr/bin/df'
            end

  TAIL_PATH = '/usr/bin/tail'

  private

  def initialize(mountpoints: DEFAULT_MOUNTPOINTS)
    super
    test_datasets(mountpoints).each_pair { |k, v| self[k] = v }
  end

  # Return list of datasets with mountpoints in MOUNTPOINTS.
  # If the datasets don't already exist, attempt to create them under
  # the current dataset (i.e., whose mountpoint contains ./).
  def test_datasets(mountpoints)
    if (mounted_datasets.keys & mountpoints).empty?
      create_test_datasets(mountpoints)
    else
      mounted_datasets.slice(*mountpoints)
    end
  end

  # Return hash of the form { 'mountpoint' => 'zfs_dataset' }.
  def mounted_datasets
    return @mounted_datasets if @mounted_datasets

    datasets = IO.popen([ZFS::ZFS_PATH, 'list', '-H'], err: %i[child out]) do |io|
      io.readlines.map do |line|
        params = line.split
        [params[-1], params[0]]
      end.to_h
    end
    raise 'Missing ZFS datasets' if $CHILD_STATUS != 0 || datasets.empty?

    @mounted_datasets = datasets
  end

  def create_test_datasets(mountpoints)
    return {} unless dot_dataset

    visited = {}
    datasets = {}
    mountpoints.each do |fs; parent, leaf, tail|
      parent, leaf, tail = fs.scan(%r{[^/]+})
      raise "Invalid mount point: #{fs}" \
        if fs !~ %r{^/} || tail || parent.nil? || leaf.nil?

      unless visited[parent]
        system ZFS::ZFS_PATH, 'create', '-o', "mountpoint=/#{parent}", "#{dot_dataset}/#{parent}"
        raise  "#{dot_dataset}/#{parent}: Failed to create dataset" unless $CHILD_STATUS == 0

        visited[parent] = true
      end

      next if datasets[fs]

      system ZFS::ZFS_PATH, 'create', '-o', "mountpoint=#{fs}", "#{dot_dataset}#{fs}"
      raise "#{dot_dataset}/#{fs}: Failed to create dataset" unless $CHILD_STATUS == 0

      datasets.merge({ fs => "#{dot_dataset}#{fs}" })
    end
    datasets
  end

  def dot_dataset
    return @dot_dataset if @dot_dataset

    io, = Open3.pipeline_r([DF_PATH, '-h', $script_dir], [TAIL_PATH, '-n+2'])
    @dot_dataset = io.gets[%r{^[^/]\S+}]
  end
end

def znap(*args)
  system 'bundle', 'exec', 'exe/znap', *args
end

def invalid_zpool
  "c#{rand(1_000...10_000)}"
end

def output_nothing
  output('').to_stdout_from_any_process
end

def output_string(string)
  output("#{string}\n").to_stdout_from_any_process
end

def output_contents_of(file)
  output(File.read("spec/data/#{file}")).to_stdout_from_any_process
end

def output_stderr_contents_of(file)
  output(File.read("spec/data/#{file}")).to_stderr_from_any_process
end

def output_matching(pattern)
  output(pattern).to_stdout_from_any_process
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.expose_dsl_globally = false

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
