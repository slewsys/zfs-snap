require 'bundler/setup'
require 'zfs/snap'

$script_name = 'znap'

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
