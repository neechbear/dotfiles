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
‘/home/nicolaw/bin/assert.sh’ -> ‘../dotfiles/bin/assert.sh’
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

Examples:

 * `dotfiles/.bashrc~%linux`
 * `dotfiles/.bachrc~%darwin,%freebsd`
 * `dotfiles/.bash_logout~@myhostname.domain.com+%ubuntu-trusty`

Where more than one file matches a host, a weighting order is applied to the
file identities, and the highest weighted file is used. See
`dotfiles/bin/dotfiles-file-weights` for an example.

