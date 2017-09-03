# $test_mnts is assumed to be a list of ZFS filesystem mountpoints
# safe for testing creation and deletion of snapshots.
# NB: It must be defined before requiring 'spec_helper'.
$test_mnts =   ['/tmp', '/var/tmp', '/var/crash']

require 'spec_helper'
require 'zfs/snap/cli'

RSpec.describe Zfs::Snap do
  let(:mounted_datasets) { zfs_mounted_datasets }
  let(:test_datasets) { zfs_test_datasets }

  context 'command-line options' do
    it 'prints a version number' do
      expect { znap '-V' }.to output_string('Znap ' + Zfs::Snap::VERSION)
    end

    it 'summarizes usage if no arguments' do
      expect { znap '-h' }.to output_contents_of('help.txt')
    end

    it 'summarizes usage with option -h' do
      expect { znap '-h' }.to output_contents_of('help.txt')
    end

    it 'summarizes usage with option -c and missing dataset' do
      expect { znap '-c' }.to output_contents_of('help.txt')
    end

    it 'summarizes usage with option -d and missing snapshot' do
      expect { znap '-d' }.to output_contents_of('help.txt')
    end

    it 'complains about an invalid frequency argument to option -c' do
      expect { znap '-cfoo,2w', 'c0'  }.to \
        output_stderr_contents_of('invalid-frequency.txt')
    end

    it 'complains about an invalid lifespan argument to option -c' do
      expect { znap '-chourly,foo', 'c0'   }.to \
        output_stderr_contents_of('invalid-lifespan.txt')
    end
  end

  context 'creating ZFS filesystem snapshots' do
    before do
      raise RuntimeError, 'test_datasets: empty' if test_datasets.empty?
    end

    it 'complains about invalid ZFS filesystems given option -c' do
      expect { znap '-chourly,2w', 'c0', 'c1' }.to \
        output_stderr_contents_of('invalid-dataset.txt')
    end

    # Create two snapshots, one of which expires immediately.
    it 'creates snapshots' do
      expect { znap '-chourly,0S', test_datasets[0] }.to \
        output_matching(/^#{test_datasets[0]}@hourly-.*0S: created$/)
      expect { znap '-cdaily,1w', test_datasets[0] }.to \
        output_matching(/^#{test_datasets[0]}@daily-.*1w: created$/)
    end

  end

  context 'listing ZFS filesystem snapshots' do
    before do
      raise RuntimeError, 'test_datasets: empty' if test_datasets.empty?
    end

    # List each snapshot separately by regex.
    it 'lists snapshots' do
      expect { znap '-l', "#{test_datasets[0]}.*0S" }.to \
        output_matching(/^#{test_datasets[0]}@hourly-.*0S$/)
      expect { znap '-l', "#{test_datasets[0]}.*1w" }.to \
        output_matching(/^#{test_datasets[0]}@daily-.*1w$/)
    end
  end

  context 'expiring ZFS filesystem snapshots' do
    before do
      raise RuntimeError, 'test_datasets: empty' if test_datasets.empty?
    end

    # Destroy expired snapshot, then verify unexpired snapshot still exists.
    it 'expires snapshots' do
      expect { znap '-e', test_datasets[0] }.to \
        output_matching(/^#{test_datasets[0]}@hourly-.*0S: destroyed$/)
      expect { znap '-l', test_datasets[0] }.to \
        output_matching(/^#{test_datasets[0]}@daily-.*1w$/)
    end
  end

  context 'destroying ZFS filesystem snapshots' do
    before do
      raise RuntimeError, 'test_datasets: empty' if test_datasets.empty?
    end

    # Destroy unexpired snapshot by regex, then verify it's gone.
    it 'destroys snapshots' do
      expect { znap '-d', test_datasets[0] }.to \
        output_matching(/^#{test_datasets[0]}@daily-.*1w: destroyed$/)
      expect { znap '-l', test_datasets[0] }.to output_nothing()
    end
  end

end
