# Computer, Log Thyself!
Parses MacOS logs into a postgres database where they can be analyzed far more easily. Useful if you think you're being monitored/hacked/etc - but probably has other uses too. Currently supports:

1. MacOS unified syslogs.
2. Logs generated by [Objective-See's new tools](https://objective-see.org/products/utilities.html) that extract/publish the data from Apple's new Endpoint Security Framework.

Soon will support the old style of MacOS logs - the ones you see in Console - as well.

### Why would I want to do this?
I wrote this because I was suspicious that my macs were being hacked. MacOS only keeps ~5-60m of logs on hand depending on what you're doing, even less if you use the more verbose logging style. And they aren't in a particularly easy to analyze format either.

For those of us who know how to interact with an SQL database having the data available in this form makes analysis much, much easier. Also I suspect if you hire a security professional to audit your system because you fear you've been hacked, the people you hire will love you if you can give them this data.

# Installation

1. Checkout or download the code. For the less git enabled among us, click the green "Code" button above, click "download zip" or similar, and unzip it. (_Advice you don't have to take: put the resulting folder somewhere sensible._)
2. If you have `homebrew`, `ruby 3.1`, and `postgresql` setup already, skip to the next step. If you _don't_ have those things (of if you have no idea what those things are), don't worry, we can still do this. There's a script that should set up everything for you but you have to get in Terminal and run it.
    1. Go to the `Applications/Utilities` folder on your Mac.
    2. Click `Terminal`. (If you've never run terminal before, congratulations: you are now officially inside your computer)
    3. Change the current directory (AKA "folder") in Terminal by typing `cd ` and then dragging the folder you downloaded this to onto the terminal. It should populate a bunch of text - the location of the folder you dragged in. Press enter and your terminal window will be in a new directory.
3. Run `scripts/initial_setup.sh` from the project directory. This will (hopefully) install the prerequisites and set up the database.

#### Installation As A Continually Running Process Managed By `launchd`

It's not necessary but you can set things up so the MacOS log stream collection launches right when you power on your computer - before you even login - for maximum monitoring power. Apple's `launchd` will also relaunch the log collector should it crash if you set this up.

There's a script to setup the launch daemon for you. It needs to be run with `sudo` privileges to install the launch daemon, so you will be prompted for your password.

```sh
sudo scripts/launchd/install_as_launch_daemon.sh
```

**NOTE:** If you want options other than the defaults, you'll have to edit [the launch script](scripts/start_log_stream_loader.sh).

### Uninstallation
Copy paste this stuff into the terminal:

```sh
# Stop the launch daemon
sudo scripts/stop_logladers.sh

# Disable the launch daemon permanently
sudo launchctl disable system/cryptadamus.logloader

# Delete the daemon's config file
sudo rm /Library/System/cryptadamus.logloader.plist

# Drop the database
psql << 'DROP DATABASE macos_log_collector_development'
psql << 'DROP DATABASE macos_log_collector_test'
```

Then delete the project folder. Uninstalling `ruby`, `homebrew`, `postgres` etc. is beyond the scope of this readme but you can figure it out.


# Usage
`**QUICKSTART**`

This should start streaming macOS system logs to the database.
```sh
thor collect:syslog:stream
```

### Other Kinds Of Usage

The Quickstart shows you how to capture logs in a stream going forward from now but the application can also capture logs from the past if OS X hasn't purged them yet. The interface is built in Thor (which I mildly regret[^1], but not enough to change it. ), the same thing as Ruby on Rails's generators. Type `thor list` and you should see something like this:

[^1]: I've never seen a project used by so many people with such a combination of broken features and atrocious - nay, profane - documentation. It's like they want you to not use it.

```sh
collect
-------
thor collect:file_monitor:stream      # Collect file events from Objective-See's File Monitor tool (requires sudo!)
thor collect:syslog:custom ARGUMENTS  # ARGUMENTS will be passed on to the 'log' command directly
thor collect:syslog:from_file FILE    # Read logs from FILE
thor collect:syslog:last INTERVAL     # Capture from INTERVAL before now using 'log show'. Example INTERVALs: 5d, 2m, 30s
thor collect:syslog:start DATETIME    # Collect logs since a given DATETIME in the past using 'log show'
thor collect:syslog:stream            # Collect logs from the syslog stream from now until you tell it to stop

db
--
thor db:dump  # Write the database to a compressed archive via pg_dump.
```

Thor will show you the command line options for each command via `thor help COMMAND`.  e.g. `thor help collect:file_monitor:stream` yields something like
```sh
Usage:
  thor collect:file_monitor:stream

Options:
  [--file-monitor-path=FILE_MONITOR_PATH]    # Path to your FileMonitor executable
                                             # Default: /Applications/FileMonitor.app/Contents/MacOS/FileMonitor
  [--file-monitor-flags=FILE_MONITOR_FLAGS]  # Flags to pass to FileMonitor command line (-pretty is not allowed)
                                             # Default: -skipApple
  [--app-log-level=LEVEL]                    # This application's logging verbosity
                                             # Default: INFO
                                             # Possible values: DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN
  [--batch-size=N]                           # Rows to process between DB loads
                                             # Default: 10000
  [--avoid-dupes], [--no-avoid-dupes]        # Attempt to avoid dupes by going a lot slower
  [--read-only], [--no-read-only]            # Just read and process the streams, don't save to the database.

Collect file events from Objective-See's File Monitor tool (requires sudo!)
```

### Configuration
Mostly it's configured from the command line but you can set some custom configuration options if you make your own `.env` file.  Start by copying the examples: `cp .env.example .env`.

### Application Logging
**This section is not about the system logs this app is capturing.** Those are written to the database. This is about the logs this application generates. _This application's_ logs are by default written to the `log/` directory in the project's root dir.  If things aren'y working, look there and maybe you'll be able to figure out what's wrong.

You can use the `RAILS_LOG_TO_STDOUT` environment variable to have them printed to `STDOUT` (AKS "the terminal window you are looking at") in real time.  e.g. you would run the stream loader like this:

```sh
RAILS_LOG_TO_STDOUT thor collect:syslog:stream
```

-------

# Analyzing The Data
`**QUICKSTART (sort of)**`

There's some [useful queries](db/queries) in the repo you can look at.

If you don't know how to write SQL queries the best thing to do would be to point a tool like Chartio at the database, which will give you some kind of GUI / charting situation. There's probably other tools like Chartio though the one I am most comfortable/familiar with and think is the best product is not really for personal use (expensive + difficult setup). The landscape may have changed in the last few years, however, so maybe look around.

If you know minimal SQL a tool like [pgAdmin](https://www.pgadmin.org) may or may not be helpful. There may be other, better tools out there as well. Feel free to suggest others. Beyond that analysis is kind of on you or whichever database wizards you can round up to look at your situation.

As far as what to look for, I recommend the [Objective-See](https://objective-see.org) website/blog.  They have many great resources to read and tools to download.

Run `man log` to read Apple's documentation of what is in the data ([here](https://www.dssw.co.uk/reference/log.html) is a link to the log manual that may or may not be current).



### System Logs
Your data will be in a database called `macos_log_collector_development`, in a table called `macos_system_logs`. It has _everything_ apple provides (or claims to provide), which is these columns:

| Name  | Data Type |
| ------------- | ------------- |
| `log_timestamp` | _datetime_ |
| `event_type` | _string_ |
| `message_type` | _string_ |
| `category` | _string_ |
| `event_message` | _string_ |
| `process_name` | _string_ |
| `sender_process_name` | _string_ |
| `subsystem` | _string_ |
| `process_id` | _string_ |
| `thread_id` | _string_ |
| `trace_id` | _decimal_ |, precision: 26, scale: 0
| `source` | _string_ |
| `activity_identifier` | _string_ |
| `parent_activity_identifier` | _decimal_ |, precision: 26, scale: 0
| `backtrace` | _json_ |
| `process_image_path` | _string_ |
| `sender_image_path` | _string_ |
| `boot_uuid` | _string_ |
| `process_image_uuid` | _string_ |
| `sender_image_uuid` | _string_ |
| `mach_timestamp` | _bigint_ |
| `sender_program_counter` | _bigint_ |
| `timezone_name` | _string_ |
| `creator_activity_id` | _decimal_ |, precision: 26, scale: 0



#### System Log Enums
There are fundamentally two kinds of log messages - events and log messages (which are classified as a kind of event: a `logEvent`). There are two ENUMs to save space when storing the `event_type` and `message_type`. Here are the possible values:


#### The Simplified View
I have learned that a lot of the columns Apple provides are actually pretty useless and/or empty, so there is also a view of the table `simplifed_system_logs` you can query that does a few things:

1. Shows only what I found to be the important columns.
2. Collapses `message_type` and `event_type` into one column that explains the type, called just `T` so it takes up less space. [See here](db/functions/msg_type_char_v01.sql) for a guide to what each letter means.


| event_types | message_types |
|------------|------------|
| activityCreateEvent | Debug
| activityTransitionEvent | Default |
| logEvent | Info |
| stateEvent | Warn |
| signpostEvent | Error |
| timesyncEvent | Fault |
| traceEvent | |
| userActionEvent | |


### Objective-See `FileMonitor` Data

The table is called `file_events`. Everything is not extracted but the original JSON data structure is stored in the database where [you can directly query it](https://www.postgresql.org/docs/12/functions-json.html) if you are familiar with the dark art of querying JSON paths via SQL queries.  See [Apple's Endpoint Security Framework documentation](https://developer.apple.com/documentation/endpointsecurity) for more info on what the data is.



# Development/Contributions
Contributions are welcome. Stuff I'm working on includes filtering, pre-unified MacOS syslogging, and a couple other things.

BTW If you're thinking to yourself, "well I only know python, I can't contribute" - let me just say that having worked with Ruby, Python, and 10-20 other languages in a professional capacity: if you know one you basically know the other.  The differences are very small compared to the differences between other languages.

If you're familiar with computers but not familiar with Ruby or Rails: this is barely a Rails app. It doesn't use Rails in the way god and man intended. But it was generated from the Rails startup script so there's a bunch of cruft. Let me point you to the very few places that matter in this monstrous default directory structure. I left the cruft there for now, on the off chance that someone wants to make some kind of frontend for this or whatever... Rails is pretty good at facilitating database interactions, even when not used as intended.

* `[app/models](app/models)`
* `[lib/](lib)`
* `[db/queries]` (where i've been putting queries i found useful)


### Running The Test Suite
```sh
bundle exec rspec
```

Test should pass before you open a pull request. New featuers should have tests... that pass.

# Other Tools
Eclectic Light
Objective-See
https://objective-see.org/products/utilities.html
