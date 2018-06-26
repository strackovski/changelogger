# **ChangeLogger**

ChangeLogger is a command line tool for updating changelog files using your project's git log. It looks for the latest tag in your git repository, reads all the commits since that tag, and updates the changelog with commit messages.

By supporting semantic versioning ChangeLogger knows how to increment your version number based on the type of release your making (major, minor or patch/hotfix).

It's written in Perl 5 and packaged into a standalone executable. Currently only tested and supported on later versions of OSX.

# Installation

## 1. Using the installation script (recommended)

On the command line run:

```
curl https://s3.eu-central-1.amazonaws.com/nv3-org/changelogger/installer.sh | bash
```

## 2. Downloading distributable files

Download the distributable built for your platform architecture: 

- [ChangeLogger 64-bit](https://s3.console.aws.amazon.com/s3/buckets/nv3-org/changelogger/dist/current/64/clogger)
- [ChangeLogger 32-bit](https://s3.console.aws.amazon.com/s3/buckets/nv3-org/changelogger/dist/current/32/clogger)
 
Move the downloaded file to your ``PATH`` directory, and make it executable. To list the PATH directories run: 
 
```
echo $PATH
```

Then execute the command below (if ``/usr/local/bin/`` is not a PATH directory, replace it with one of the directories listed by the previous command). 

```
mv clogger /usr/local/bin/clogger && chmod 755 /usr/local/bin/clogger
```

## 3. Installing from source

Requirements:

- Perl 5 interpreter
- [CPAN](https://www.cpan.org/)
- [Par::Packer module](https://metacpan.org/pod/PAR::Packer)

**Install Par::Packer**

```
cpan Par::Packer
```

**Clone source repository**

```
git clone git@bitbucket.org:nv3/clogger.git
```

**Build**

Run this command from ChangeLogger source directory:

```
pp -v -a 'includes/header.txt;header.txt' -a 'includes/config.json;config.json' -a 'includes/cacert.pem;cacert.pem' -x -o bin/clogger clogger.pl
```

This will create a file called ``clogger`` in the ``bin`` directory.  

**4. Move file to your ``PATH`` directory**

```
mv bin/clogger /usr/local/bin/clogger && chmod 755 /usr/local/bin/clogger
```

# Usage

**Run ``clogger`` to view usage instructions.**

```
clogger <RELEASE_TYPE> [--dir] [--strategy] [-vdi]
```

Where release type is one of:

```
 ➜ major
 ➜ minor
 ➜ patch (alias hotfix)
```

**Options:**

```
 --dir         Absolute path to project directory.
               Defaults to current directory.

 -=strategy    Change detection strategy:
               ➜ tag: all commits since last tag (default).
               ➜ commit: all commits since given commit.
               
 -v		       Enable verbose output to stdout.
 -d            Enable debug mode.
 -i            Display version and copyright info.
```

**Examples:**

1. Omit optional parameters to update the changelog in the current directory with changes commited after the last tag (`tag` strategy):

    ```
    $ clogger major
    ```

2. Use the `-dir` optional parameter to specify the absolute path to the directory in which to look for the changelog file and update it using default `tag` strategy:

    ```
    $ clogger major -dir=/path/to/dir
    ```

3. Use the `-strategy` optional parameter to specify the change detection strategy to use when updating the log (omitting `-dir` parameter to use the current directory):

    ```
    $ clogger major -strategy=commit
    ```

	The example above will update the changelog with changes since given commit:

    ```
    ➜  Commit hash: d615646932f6c51a9e046473fbc40c1cb0356919
    ➜  Next version/tag: 11
    ➜  Release date [26-06-2018]:
    ➜  Changelog updated in /Users/vstrackovski/Projects/orefy/CHANGELOG.md.
    ```    
    
    Semantic versioning is not required when using `commit` strategy.

4. Specify changelog file's directory and change detection strategy:

    ```
    $ clogger major -dir=/path/to/dir -strategy=commit
    ```
    
# Contributing

First apply git hooks by running:

```
./scripts/init-dev.sh
```

Push your branch and create a pull request.

# License

MIT (see LICENSE file).

© 2018 Vladimir Strackovski <vladimir.strackovski@dlabs.si>
