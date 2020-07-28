require 'bundler/setup'
require 'zfs/snap'

$script_name = 'znap'

def znap(*args)
  system 'sudo', 'bundle', 'exec', "exe/#{$script_name}", *args
end

# Return hash of the form { 'mountpoint' => 'zfs_dataset' }.
def zfs_mounted_datasets
  IO.popen([ZFS::ZFS_PATH, 'list', '-H'], err: [:child, :out]) do |io|
    io.readlines.map do |line|
      params = line.split
      [params[-1], params[0]]
    end.to_h
  end
end

# Return list of ZFS datasets whose mountpoints are in $test_mnts.
def zfs_test_datasets
  mnts = zfs_mounted_datasets
  mnts.keys.map { |key| $test_mnts.include?(key) ?  mnts[key] : nil }.compact
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
