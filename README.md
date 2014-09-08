# Snipr

Tool to manage runaway processes.  More to be written later.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'snipr'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install snipr

## Usage

#### Culling Runaway Resque Workers
```
Usage: reap_resque_workers [options]

Can be used to reap runaway resque workers that have exceeded too much memory use, CPU use, or time alive.
By default, this sends USR1 to the parent worker process, which causes it to immediately kill the runaway
child.  The parent will then spawn another child to continue work.

Options:
    -m, --memory [BYTES]             Workers using more than some bytes size of memory
    -c, --cpu [PERCENTAGE]           workers using more than a percentage of CPU
    -a, --alive [SECONDS]            Workers that have been alive for some length of time in seconds
    -s, --signal [SIGNAL]            Signal to send to the worker's parent.  Defaults to USR1.
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/snipr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
