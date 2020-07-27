# Zfs::Snap

__Zfs::Snap__ is a Ruby library for managing ZFS snapshots.

Snapshots are named in the format:  `DATASET`@`FREQUENCY`-`TIMESTAMP`--`LIFESPAN`,

where

* DATASET is the name of an existing ZFS filesystem.

* FREQUENCY indicates how often these snapshots are created. Its value
  is one of: `hourly`, `daily`, `weekly`, `monthly`.

* TIMESTAMP is an ISO 8601 UTC timestamp indicating the snapshot's
  date of creation. Its value in strftime(3) format: `%Y%m%d`T`%H%M%S%`z.

* LIFESPAN is the time interval between snapshot creation and
  expiration. Its value in regex(3) format: `[[:digit]]+[dwmyHMS]`,
  e.g., `2w` indicates two weeks and `2m` two months.

Command-line utility, `znap` (described below), is intended to be run
from `cron(8)` for periodically creating snapshots and destroying
expired ones.

## System Requirements

A ZFS filesystem, a recent version of the
[Ruby](https://www.ruby-lang.org/en/) interpreter (e.g., ruby 2.5)
and, for automatic snapshot rotation, `cron(8)`.

For development/testing, Ruby test framework `Rspec` version 3.9.

## Installation
Run the following commands from a Unix shell:

```bash
git clone https://github.com/slewsys/zfs-snap.git
cd ./zfs-snap
sudo gem update --system
bundle
rake build
sudo gem install pkg/clean_rm*.gem
```

Prior to running the RSpec test suite,
edit the file *spec/zfs/snap_spec.rb* and change the line at the top
of the file:

```ruby
$test_mnts =   ['/test1', '/test2', '/test3']
```

Replace `/test1`, `/test2`, `/test3` with locally mounted ZFS filesystems for
which test snapshots can be created and destroyed. The testsuite can
then be run as:

```bash
bundle exec rspec spec
```

## Command-line Interface

```
Usage: znap -h | --help
       znap [-nr] -c | --create[=FREQ,SPAN] DATASET ...
       znap [-nr] -d | --destroy REGEX ...
       znap [-nr] -e | --expire [REGEX ...]
       znap [-nr] -l | --list [REGEX ...]"
Options:
    -h, --help         Show this message, then exit.
    -c[FREQ,SPAN],     For each dataset given, create snapshot named per
                       specified FREQUENCY and LIFESPAN. If option arguments
                       are not specified, they default to: hourly,2w.
        --create
    -d, --destroy      Destroy snapshots matching regular expressions
                       REGEX ... . At least one regular expression
                       must be provided to protect against inadvertently
                       destroying all snapshots.
    -e, --expire       Destroy expired snapshots matching regular expressions
                       REGEX ... . If no regular expression is specified,
                       then all expired snapshots are destroyed.
    -l, --list         List snapshots matching regular expressions REGEX
                       ... . If no regular expression is specified, then
                       all snapshots are listed.
    -n, --no-execute   When combined with one of the flags -c, -d or
                       -e, display commands that would be executed, but
                       don't actually execute them.
    -r, --recursively  When combined with one of the flags -c, -d, -e
                       or -l, recursively act on any children of the dataset.
    -V, --version      Show version, then exit.
    -v, --verbose      Report diagnostics.

```

## Example `crontab(5)`

```
# Remove extraneous snapshots hourly.
13 6-22 * * * root znap -d -r /usr/obj /var/cache /var/tmp
# Remove expired snapshots daily.
 0    6 * * * root znap -e

# Create hourly snapshots from 6 AM to 10 PM lasting 2 weeks
12 6-22 * * * root znap -chourly,2w  -r zroot/ROOT/default zroot/usr zroot/var zroot/opt
# Create daily snapshots lasting 3 months
 6    5 * * * root znap -cdaily,3m   -r zroot/ROOT/default zroot/usr zroot/var zroot/opt
# Create weekly snapshots lasting 13 months.
 7    6 * * 0 root znap -cweekly,13m -r zroot/ROOT/default zroot/usr zroot/var zroot/opt
# Create monthly snapshots lasting 2 years.
 8    7 1 * * root znap -cmonthly,2y -r zroot/ROOT/default zroot/usr zroot/var zroot/opt
```

## Contributing

Bug reports and pull requests can be sent to
[GitHub zfs-snap](https://github.com/slewsys/zfs-snap).

## License

This Rubygem is free software. It can be used and redistributed under
the terms of the [MIT License](http://opensource.org/licenses/MIT).
