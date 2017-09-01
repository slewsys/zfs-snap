require 'spec_helper'
require 'zfs/snap/cli'

RSpec.describe Zfs::Snap do
  it "has a version number" do
    expect(Zfs::Snap::VERSION).not_to be nil
  end

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
      expect { znap '-cfoo,2w', 'c0'  }.to output_stderr_contents_of('invalid-frequency.txt')
    end

    it 'complains about an invalid lifespan argument to option -c' do
      expect { znap '-chourly,foo', 'c0'   }.to output_stderr_contents_of('invalid-lifespan.txt')
    end

    it 'complains about invalid ZFS filesystems given option -c' do
      expect { znap '-chourly,2w', 'c0', 'c1'  }.to output_stderr_contents_of('invalid-dataset.txt')
    end
  end
end
