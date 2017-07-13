# dotfiles

Installation is as simple as:

```bash
git clone https://github.com/neechbear/dotfiles.git
dotfiles/bin/dotfiles.sh install
dotfiles/bin/dotfiles-symlink-files dotfiles/ ~
```

It may look something like this:

```
nicolaw@laptop:~$ git clone https://github.com/neechbear/dotfiles.git
Cloning into 'dotfiles'...
remote: Counting objects: 3, done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (3/3), done.
Checking connectivity... done.
nicolaw@laptop:~$ cd dotfiles/
nicolaw@laptop:~/dotfiles$ bin/dotfiles.sh install
‘bin/dotfiles-available-identities’ -> ‘dotfiles.sh’
‘bin/dotfiles-file-weights’ -> ‘dotfiles.sh’
‘bin/dotfiles-symlink-files’ -> ‘dotfiles.sh’
‘bin/dotfiles-normalised-files’ -> ‘dotfiles.sh’
‘bin/dotfiles-best-file’ -> ‘dotfiles.sh’
nicolaw@laptop:~/dotfiles$ bin/dotfiles-symlink-files ~/dotfiles/ ~
‘/home/nicolaw/bin/dotfiles-symlink-files’ -> ‘../dotfiles/bin/dotfiles-symlink-files’
‘/home/nicolaw/bin/dotfiles-available-identities’ -> ‘../dotfiles/bin/dotfiles-available-identities’
‘/home/nicolaw/bin/dotfiles-normalised-files’ -> ‘../dotfiles/bin/dotfiles-normalised-files’
‘/home/nicolaw/bin/dotfiles-file-weights’ -> ‘../dotfiles/bin/dotfiles-file-weights’
‘/home/nicolaw/bin/dotfiles-best-file’ -> ‘../dotfiles/bin/dotfiles-best-file’
‘/home/nicolaw/bin/dotfiles.sh’ -> ‘../dotfiles/bin/dotfiles.sh’
nicolaw@laptop:~/dotfiles$
```

You can then put files inside your dotfiles directory that will either get
symlinked in to place on all your machines, or name them with a special
`~IDENTITY` suffix, this limiting which machines that particular file will be
symlinked on.

Available identiies can be found with the `dotfiles-available-identities`
command.

```
nicolaw@laptop:~/dotfiles$ bin/dotfiles-available-identities
@laptop
@laptop.home.nicolaw.co.uk
%debian
%linux
%linux-4.4.0-45-generic
@home.nicolaw.co.uk
%xenial
%ubuntu
%ubuntu-16.04
%ubuntu-xenial
```

Multiple identities can be applied to a file by delimiting them with comma `,`
characters.

Composite identities requiring more than one identity to be matched can be
applied by concatinating them with the plus `+` character.


## Examples

* `dotfiles/.bashrc~%linux`
* `dotfiles/.bachrc~%darwin,%freebsd`
* `dotfiles/.bash_logout~@myhostname.domain.com+%ubuntu-trusty`

Where more than one file matches a host, a weighting order is applied to the
file identities, and the highest weighted file is used. See
`dotfiles/bin/dotfiles-file-weights` for an example.

Here we create a couple of different `.examplerc` files. The first is intended
to be used on Ubuntu and Debian based hosts; the second on RedHat and Fedora.

```
nicolaw@laptop:~$ echo "# Debian family example config file" > 'dotfiles/.examplerc~%ubuntu,%debian'
nicolaw@laptop:~$ echo "# RedHat family example config file" > 'dotfiles/.examplerc~%redhat,%fedora'
```

Next we re-run the `dotfiles-symlink-files` command, giving `~/dotfiles/` as the
source directory containing your configuration files that you want to be
symlinked to, and the second argument `~` indicating the files should be linked
in to your home directory.

```
nicolaw@laptop:~$ dotfiles-symlink-files ~/dotfiles/ ~
‘/home/nicolaw/bin/dotfiles-normalised-files’ -> ‘../dotfiles/bin/dotfiles-normalised-files’
‘/home/nicolaw/bin/dotfiles-available-identities’ -> ‘../dotfiles/bin/dotfiles-available-identities’
‘/home/nicolaw/bin/dotfiles-best-file’ -> ‘../dotfiles/bin/dotfiles-best-file’
‘/home/nicolaw/bin/dotfiles-file-weights’ -> ‘../dotfiles/bin/dotfiles-file-weights’
‘/home/nicolaw/bin/dotfiles.sh’ -> ‘../dotfiles/bin/dotfiles.sh’
‘/home/nicolaw/bin/dotfiles-symlink-files’ -> ‘../dotfiles/bin/dotfiles-symlink-files’
‘/home/nicolaw/.examplerc’ -> ‘dotfiles/.examplerc~%ubuntu,%debian’
nicolaw@laptop:~$ ll .examplerc
lrwxrwxrwx 1 nicolaw nicolaw 35 Nov  1 23:09 .examplerc -> dotfiles/.examplerc~%ubuntu,%debian
nicolaw@laptop:~$ cat .examplerc
# Debian family example config file
nicolaw@laptop:~$
```


## Cleaning Up

If you have renamed or deleted a number of files inside your dotfiles directory,
then you may be left with a number of old broken dangling symlinks.

You can use the `find` command to locate such broken symlinks, and then delete
them.

First find the broken symlinks and check that you're happy to delete them (that
your find command didn't find any false positives):

```
find ~ -lname '*/dotfiles/*' ! -execdir test -e '{}' \; -print
```

If you're happy with the results, simply add the `-delete` argument on the end
of the find command:

```
find ~ -lname '*/src/rcfiles/*' ! -execdir test -e '{}' \; -print -delete
```


## License

MIT License

Copyright (c) 2016 Nicola Worthington <nicolaw@tfb.net>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.



