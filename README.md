# Elastic Shell

Elastic Shell (or Elash in abbreviation) is a set of utilities that manage Elasticsearch and are purely written in Bash Shell.

It supports basic management of Elasticsearch index, snapshot, etc, and also provides assistance on some advanced Elasticsearch management tasks such as reindex, upgrade, etc.

Run `elash --help` from command line to learn more.

## How to run?

Elastic Shell can run either inside or outside Docker container.

The Docker image has installed Elastic Shell with all its dependencies, such as `curl`, `jq`, etc. Hence, you don't have to install them by yourself. To run in Docker container, simply pull the image from Docker Hub.
```
docker pull morningspace/elastic-shell
```

You can also run Elastic Shell without Docker. Since it's just a set of shell scripts, you can download and put it somewhere, create a soft link to `bin/main.sh`, or add into PATH environment variable, so that you can run it from anywhere.

## Sample data

There are some sample documents distributed along with Elastic Shell. If you have no data at hand, feel free to populate them into your Elasticsearch deployment for testing or demonstration purpose.

Those located in `lib/config/index/github` are actually GitHub issues as a snapshot grabbed from [Elasticsearch](https://github.com/elastic/elasticsearch) GitHub repository using [GitHub API](https://developer.github.com/), e.g. `bulk-open-issues.json` includes all open issues and `bulk-closed-issues.json` includes part of closed issues.

Those located in `lib/config/index/companydatabase` are from [this post](http://ikeptwalking.com/elasticsearch-sample-data/). It includes a dataset with 100k employees that are generated randomly. Thanks to the author.

## Difference with Curator

[Curator](https://github.com/elastic/curator) is a great tool written in Python to manage Elasticsearch indices. Elastic Shell is not going to replace it, but a lightweight supplement, although there is a bit of overlap on functionality. Elastic Shell is much more focusing on providing assistance on some advanced Elasticsearch management tasks such as reindex, upgrade, and it's purely shell-based without Python installed, which gives people just another option.

More discussion on this can be found [here](https://discuss.elastic.co/t/looking-for-shell-based-elasticsearch-client-or-something-similar-to-curator-run-in-command-line/166009/5).
