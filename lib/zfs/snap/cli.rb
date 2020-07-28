require 'optparse'
require 'zfs/snap/version'
require 'zfs/snap/ui_console'

module ZFS
  module Snap
    class CLI
      attr_reader :option

      def initialize(option = {})
        @option =
          {
           create:      {},
           destroy:     false,
           expire:      false,
           list:        false,
           recursively: false,
           verbose:     false,
          }.merge(option)
      end

      def parse_opts(argv)
        parser = OptionParser.new(nil, 24) do |opts|
          opts.banner = <<EOF
Usage: #{$script_name} -h | --help
       #{$script_name} [-nr] -c | --create[=FREQ,SPAN] DATASET ...
       #{$script_name} [-nr] -d | --destroy REGEX ...
       #{$script_name} [-nr] -e | --expire [REGEX ...]
       #{$script_name} [-nr] -l | --list [REGEX ...]"
EOF
          opts.separator 'Options:
    In the following, REGEX is an extended regular expression per Regexp.
    '
          opts.on('-h', '--help', '
              Show this message, then exit.') do
            puts opts
            exit $err_status
          end

          opts.on('-c[FREQ,SPAN]', '--create[=FREQ,SPAN]', Array, "
              For each dataset given, create snapshot named per specified
              FREQUENCY and LIFESPAN. If no option arguments are given,
              they default to: #{Snap::DEFAULTS.values.join(',')}.") do |list|
            @option[:create] =
              list.nil? ? Snap::DEFAULTS : Snap.validate_params(*list)
          end

          opts.on('-d', '--destroy', '
              Destroy snapshots matching regular expressions REGEX ...
              At least one regular expression must be provided to
              protect against inadvertently destroying all snapshots.') do
            @option[:destroy] = true
          end

          opts.on('-e', '--expire', '
              Destroy expired snapshots matching regular expressions REGEX ...
              If no regular expression is given, then all expired snapshots
              are destroyed.') do
            @option[:expire] = true
          end

          opts.on('-l', '--list', '
              List snapshots matching regular expressions REGEX ... If no
              regular expression is given, then all snapshots are listed.') do
            @option[:list] = true
          end

          opts.on('-n', '--no-execute', "
              When combined with one of the flags -c, -d or -e, display
              commands that would be executed, but don't actually execute them.") do
            @option[:no_exec] = true
            @option[:verbose] = true
          end

          opts.on('-r', '--recursively', '
              When combined with one of the flags -c, -d, -e, or -l,
              recursively act on any children of the dataset.') do
            @option[:recursively] = true
          end

          opts.on('-V', '--version', '
              Show version, then exit.') do
            puts "#{$script_name.capitalize} #{Snap::VERSION}"
            exit $err_status
          end

          opts.on('-v', '--verbose', '
              Report diagnostics.') do
            @option[:verbose] = true
          end
        end

        begin
          parser.parse(argv)
        rescue ArgumentError, StandardError => err
          $stderr.puts "#{$script_name}: #{err.message}"
          exit $err_status
        end
      end
    end
  end
end

# Local variables:
# Mode: ruby
# coding: utf-8-unix
# End:
