require 'open3'
require 'bundler/setup'
require 'zfs/snap'

$script_dir = File.expand_path(File.dirname(__FILE__))

# $default_mountpoints are ZFS filesystem mountpoints of datasets that can be
# (possibly created and) safely deleted. They are used for snapshot
# testing. The mountpoints are expected to be of the format:
#   /parent1/child1, /parent1/child2, ...
#   /parent2/child1, /parent2/child2, ...
$default_mountpoints = %w[/zfs-snap/test1 /zfs-snap/test2 /zfs-snap/test3]

DF_PATH = case RbConfig::CONFIG['host_os']
           when /linux/, /freebsd/
             '/bin/df'
           when /solaris/
             '/usr/bin/df'
           else
             nil
          end

TAIL_PATH = '/usr/bin/tail'

class TestData < Hash
  private

  def initialize(mountpoints: $default_mountpoints)
    @mountpoints = mountpoints
    @mounted_datasets = get_mounted_datasets
    @dot_dataset = get_dot_dataset
    get_test_datasets.each_pair { |k, v| self[k] = v }
  end

  # Return list of datasets with mountpoints in @mountpoints.
  # If the datasets don't already exist, attempt to create them under
  # the current dataset (i.e., that contains ./).
  def get_test_datasets
    if (@mounted_datasets.keys & @mountpoints).empty?
      create_test_datasets
    else
      @mounted_datasets.slice(*@mountpoints)
    end
  end

  # Return hash of the form { 'mountpoint' => 'zfs_dataset' }.
  def get_mounted_datasets
    datasets = IO.popen([ZFS::ZFS_PATH, 'list', '-H'], err: [:child, :out]) do |io|
      io.readlines.map do |line|
        params = line.split
        [params[-1], params[0]]
      end.to_h
    end
    raise RuntimeError, "Missing ZFS datasets" if $? != 0 or datasets.empty?
    datasets
  end

  def create_test_datasets
    return {} if !@dot_dataset

    visited = {}
    datasets = {}
    @mountpoints.each do |fs; parent, leaf, tail|

      # Expected form of test mountpoints: /parent/leaf
      parent, leaf, tail = fs.scan(/[^\/]+/)
      raise RuntimeError, "Invalid mount point: #{fs}" \
        if (fs !~ /^\// || tail || parent.nil? || leaf.nil?)

      if !visited[parent]
        system ZFS::ZFS_PATH, 'create', '-o', "mountpoint=/#{parent}", "#{@dot_dataset}/#{parent}"
        raise RuntimeError, "#{@dot_dataset}/#{parent}: Failed to create dataset" if $? != 0
        visited[parent] = true
      end

      if !datasets[fs]
        system ZFS::ZFS_PATH, 'create', '-o', "mountpoint=#{fs}", "#{@dot_dataset}#{fs}"
        raise RuntimeError, "#{@dot_dataset}/#{fs}: Failed to create dataset" if $? != 0
        datasets.merge({fs => "#{@dot_dataset}#{fs}"})
      end
    end
    datasets
  end

  def get_dot_dataset
    io, ts = Open3.pipeline_r([DF_PATH, '-h', $script_dir], [TAIL_PATH, '-n+2'])
    @dot_dataset = io.gets[/^[^\/]\S+/]
  end
end

def znap(*args)
  system 'bundle', 'exec', 'exe/znap', *args
end

def invalid_zpool
  "c#{rand(10)}"
end

def output_nothing()
  output('').to_stdout_from_any_process
end

def output_string(string)
  output(string + "\n").to_stdout_from_any_process
end

def output_contents_of(file)
  output(File.read('spec/data/' + file)).to_stdout_from_any_process
end

def output_stderr_contents_of(file)
  output(File.read('spec/data/' + file)).to_stderr_from_any_process
end

def output_matching(pattern)
  output(pattern).to_stdout_from_any_process
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
