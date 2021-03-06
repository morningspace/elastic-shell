# Elastic Shell ![version v0.6](https://img.shields.io/badge/version-v0.6-brightgreen.svg) ![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)

Elastic Shell (or Elash in abbreviation) is a set of utilities that manage Elasticsearch and are purely written in Bash Shell.

It supports basic management of Elasticsearch index, snapshot, etc, and also provides assistance on some advanced Elasticsearch management tasks such as reindex, upgrade, etc.

Run `elash --help` from command line to learn more.

You can also watch the tutorial **"Elastic Shell 101"** video series on [YouTube](https://www.youtube.com/watch?v=9r_RNz89SVw&list=PLVQM6jLkNkfoJSTI2BgEZ4lwWT-dfsf51) or [YouKu](https://v.youku.com/v_show/id_XNDEwNjI0OTk2OA==.html?f=52133377). Or, read the corresponding posts on [晴耕小筑](https://morningspace.github.io/tags/#studio-elash-101).

| Title | Links
| ---- 	|:----
| Elastic Shell 101: Getting Started | [Post](https://morningspace.github.io/tech/elash101-1/) [YouTube](https://youtu.be/9r_RNz89SVw) [YouKu](https://v.youku.com/v_show/id_XNDEwNjI0OTk2OA==.html?f=52133377) 
| Elastic Shell 101: Working with Index | [Post](https://morningspace.github.io/tech/elash101-2/) [YouTube](https://youtu.be/nWX8miFbRPQ) [YouKu](https://v.youku.com/v_show/id_XNDExNjc0OTU4NA==.html?f=52133377)
| Elastic Shell 101: Manage Snapshot Interactively | [Post](https://morningspace.github.io/tech/elash101-3/) [YouTube](https://youtu.be/_KwIkjoRQS8) [YouKu](https://v.youku.com/v_show/id_XNDEyODY2NTA3Mg==.html?f=52133377)
| Elastic Shell 101: Reindex Using Dialog | [Post](https://morningspace.github.io/tech/elash101-4/) [YouTube](https://youtu.be/ywgxY1h0PsA) [YouKu](https://v.youku.com/v_show/id_XNDEzNTMwMTU5Ng==.html?f=52133377)
| Elastic Shell 101: Advanced Features | [Post](https://morningspace.github.io/tech/elash101-5/) [YouTube](https://youtu.be/wc4CnChWxPE) [YouKu](https://v.youku.com/v_show/id_XNDE1NTQ1NjIwNA==.html?f=52133377)

## How to run?

Elastic Shell can run either inside or outside Docker container.

The Docker image has installed Elastic Shell with all its dependencies, such as `curl`, `jq`, `dialog`, etc. Hence, you don't have to install them by yourself. To run in Docker container, simply pull the image from Docker Hub.
```
docker pull morningspace/elastic-shell
```

You can also run Elastic Shell without Docker. Since it's just a set of shell scripts, you can download and put it somewhere, create a soft link to `bin/main.sh`, or add into PATH environment variable, so that you can run it from anywhere.

## Interactive mode

Elastic Shell can be run not only as CLI command, but also in interactive mode, where it allows you to input values according to prompts and check outputs in interactive manner.

To run in interactive mode, you can specify either one of the below two options:

* --ui-text, the pure text-based user interface.

![](images/ui-text.png)

* --ui-dialog, the dialog-based user interface with better user interactive experience. It requires `dialog` to be installed as a dependency.

![](images/ui-dialog.png)

## Trouble shooting

### Enable logging

Elastic Shell uses `syslogd` to output its logs. When use the Docker image, it's been configured out of the box. Just run `syslogd` from command line in container, you will see the logs in `/var/log/elash.log`.

If not use the Docker image, you need to put the `etc/syslog.conf` under `/etc` then start `syslogd` by yourself.

### Dry run

Some operations, e.g. to delete index, may be dangerous. To avoid mistake, you can run Elastic Shell in dry run mode before run in production environment.

To enable dry run, add option `--dry-run` when run Elastic Shell from command line. e.g.
```
elash index --dry-run delete github
```

Instead of sending request to server, it always returns the fake response. You can customize the response by modifying `config/dryrun.properties`. For each request, add the full path URL as key, and the designated fake response as value. When in dry run mode, Elastic Shell will find the entry that matches the request URL, and print the pre-defined response as if it's returned from server.

## Auto completion

Elastic Shell supports auto completion when you type commands from command line.

The Docker image has installed `bash completion` and enabled this feature for you by default. To trigger it when you type commands, press two tabs, then it will give you the suggestions based on the context.

If not use the Docker image, you can run below command to source the completion definition script file from command line manually:
```
source bin/common/completion.sh
```

Or add it into ~/.bashrc so that can be enabled automatically anytime when you open a new terminal window.

## Dependencies

Elastic Shell has a few dependencies to make it work. You may need to install them by yourself if not use the Docker image. 

Most of the dependencies are optional. There will be alternatives or feature restricted if they are not installed.

|Dependency			|If Not Installed
|:----					|:----
|curl           |launch in dry run mode
|jq             |some features may not be available, e.g. JSON prettify
|dialog         |dialog mode disabled
|bash completion|commands auto completion disabled

## Sample data

There are some sample documents distributed along with Elastic Shell. If you have no data at hand, feel free to populate them into your Elasticsearch deployment for testing or demonstration purpose.

Those located in `lib/config/index/github` are actually GitHub issues as a snapshot grabbed from [Elasticsearch](https://github.com/elastic/elasticsearch) GitHub repository using [GitHub API](https://developer.github.com/), e.g. `bulk-open-issues.json` includes all open issues and `bulk-closed-issues.json` includes part of closed issues.

Those located in `lib/config/index/companydatabase` are from [this post](http://ikeptwalking.com/elasticsearch-sample-data/). It includes a dataset with 100k employees that are generated randomly. Thanks to the author.

## Difference with Curator

[Curator](https://github.com/elastic/curator) is a great tool written in Python to manage Elasticsearch indices. Elastic Shell is not going to replace it, but a lightweight supplement, although there is a bit of overlap on functionality. Elastic Shell is much more focusing on providing assistance on some advanced Elasticsearch management tasks such as reindex, upgrade, and it's purely shell-based without Python installed, which gives people just another option.

More discussion on this can be found [here](https://discuss.elastic.co/t/looking-for-shell-based-elasticsearch-client-or-something-similar-to-curator-run-in-command-line/166009/5).
