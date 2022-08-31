require 'date'
require 'time'

class IO
  class <<self
    def suppress(*streams)
      saved_streams = streams.collect { |stream| stream.dup }
      streams.each do |stream|
        stream.reopen('/dev/null')
        stream.sync = true
      end
      yield
    ensure
      streams.each_with_index do |stream, i|
        stream.reopen(saved_streams[i])
      end
    end
  end
end

# When converted to int, time zone converted to UTC automatically.
module ZFS
  ZFS_PATH = case RbConfig::CONFIG['host_os']
             when /linux/, /freebsd/
               '/sbin/zfs'
             when /solaris/
               '/usr/sbin/zfs'
             else
               nil
             end

  class <<self
    def snapshot?(dataset)

      # Work around Linux ZFS issue where the command:
      #     zfs list -type snapshot dataset
      # succeeds if dataset exists but is not a snapshot.
      return false if dataset.index('@').nil?

      IO.suppress($stdout, $stderr) do
        system ZFS_PATH, 'list', '-t', 'snapshot', dataset
      end
    end

    def dataset?(dataset)
      IO.suppress($stdout, $stderr) do
        system ZFS_PATH, 'list', dataset
      end
    end

    def type_of?(dataset)
      snapshot?(dataset) ? :snapshot : dataset?(dataset) ? :dataset : :unknown
    end
  end

  module Snap
    SECONDS =
      {
       d: 86400,
       w: 604800,
       m: 2592000,
       y: 31536000,
       H: 3600,
       M: 60,
       S: 1
      }

    FREQUENCIES =
      [
       :hourly,
       :daily,
       :weekly,
       :monthly
      ]

    DEFAULTS =
      {
       frequency: 'hourly',
       lifespan: '2w'
      }


    class <<self
      def each
        IO.popen([ZFS_PATH, 'list', '-H', '-t', 'snapshot'],
                 :err => [:child, :out]) do |io|
          io.readlines.map { |line| line.split[0] }.each do |snapshot|
            yield Dataset.new(snapshot)
          end
        end
      end

      def scan(pattern)
        IO.popen([ZFS_PATH, 'list', '-H', '-t', 'snapshot'],
                 :err => [:child, :out]) do |io|
          io.readlines.map { |line| line.split[0] }.map do |snapshot|
            Dataset.new(snapshot) if snapshot =~ /#{pattern}/
          end.compact
        end
      end

      def validate_frequency(freq)
        if !FREQUENCIES.include? freq.to_sym
          $err_status = 1
          raise ArgumentError,
            "#{freq}: Invalid frequency - expecting: #{FREQUENCIES.join('|')}"
        end
        freq
      end

      def validate_lifespan(span)
        if span !~ /^[[:digit:]]+[#{SECONDS.keys.join}]$/
          $err_status = 1
          raise ArgumentError,
            "#{span}: Invalid lifespan - expecting: [[:digit:]]+[#{SECONDS.keys.join}]}"
        end
        span
      end

      def validate_params(freq, span)
        {
         frequency: validate_frequency(freq),
         lifespan: validate_lifespan(span)
        }
      end
    end

    class Dataset
      attr_reader :name

      def initialize(dataset, params: DEFAULTS, ui_module: :Console)

        # Include ui_module to expose `respond' and `error' methods...
         self.class.include(Object.const_get ui_module)

        case ZFS.type_of? dataset
        when :snapshot
          @name = dataset
        when :dataset
          stamp= Time.now.utc.iso8601.gsub(/-|:/, '')
          @name = "#{dataset}@#{params[:frequency]}-#{stamp}--#{params[:lifespan]}"
        else
          error "#{dataset}: Invalid ZFS dataset"
          @name = nil
        end
      end

      def expired?
        if /(?<ts>\d+T\d+Z)--(?<age>\d+)(?<span>\w+)/ =~ name
          origin = DateTime.strptime(ts, '%Y%m%dT%H%M%S%z').to_time
          Time.now >= origin + age.to_i * SECONDS[span.to_sym]
        end
      end

      def create(request)
        command = [ZFS_PATH, 'snap']
        command.append '-r' if request[:recursively]
        command.append name
        respond command.join(' ') if  request[:verbose]
        result = IO.suppress do
          system(*command) if !request[:no_exec]
        end
        respond "#{name}: create%s" %
          [result ? 'd' : ' failed',
           request[:recursively] ? ' (recursively)' : ''] if !request[:no_exec]
      end

      def destroy(request)
        command = [ZFS_PATH, 'destroy']
        command.append '-r' if request[:recursively]
        command.append name
        respond command.join(' ') if  request[:verbose]
        result = IO.suppress do
          system(*command) if !request[:no_exec]
        end
        respond "#{name}: destroy%s%s" %
          [result ? 'ed' : ' failed',
           request[:recursively] ? ' (recursively)' : ''] if !request[:no_exec]
      end
    end
  end
end
