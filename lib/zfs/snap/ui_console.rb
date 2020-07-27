require 'io/console'

module Console
  def respond(*args)
    puts args
  end

  def error(*args)
    $stderr.puts "#{$script_name}: #{args.join(' ')}"
    $err_status = 1
    false
  end

  def confirm(action, file, default = 'n')
    default_response =
      case default
      when /n.*/ || /N.*/
        prompt = '[y|N]? '
        false
      else
        prompt = '[Y|n]? '
        true
      end

    $stderr.print "#{action}: #{file}: #{prompt}"
    ch = $stdin.getch(min: 1).codepoints.first

    case ch
    when *['y', 'Y', ].map(&:ord)
      $stderr.puts "#{ch.chr}"
      true
    when *['n', 'N'].map(&:ord)
      $stderr.puts "#{ch.chr}"
      false
    when 3                      # CTRL-C
      $stderr.puts "\n#{$script_name}: User cancelled"
      exit
    else
      $stderr.puts "#{ch.chr}"
      default_response
    end
  end
end

# Local variables:
# Mode: ruby
# coding: utf-8-unix
# End:
