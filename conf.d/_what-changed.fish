function _what-changed_install --on-event what-changed_install
    # Set universal variables, create bindings, and other initialization logic.
end

function _what-changed_update --on-event what-changed_update
    # Migrate resources, print warnings, and other update logic.
end

function _what-changed_uninstall --on-event what-changed_uninstall
    # Erase "private" functions, variables, bindings, and other uninstall logic.
end

status is-interactive; or return

set -g WHAT_CHANGED_MAXDEPTH 1
set -g WHAT_CHANGED_VERBOSE 0
set -g WHAT_CHANGED_USE_PREFIX 1
set -g WHAT_CHANGED_DISABLED 0
# _what_changed_ is used as a namespace prefix for variables, to avoid collisions
set -g _what_changed_directory_contents_before_command * .*
set -g _what_changed_last_directory $PWD
# set -g _what_changed_echo_prefix "[what-changed.fish]"
set -g _what_changed_echo_prefix (printf "[%swhat%s-%schanged%s.fish]" (set_color green) (set_color normal) (set_color red) (set_color normal))

function whatchanged
    set -l options (fish_opt --short=h --long=help)
    if not argparse $options -- $argv
        whatchanged --help
        return 1
    end

    if set --query _flag_help
        set -l usage "$(set_color --bold)Interact with what-changed.fish$(set_color normal)

$(set_color yellow)Usage:$(set_color normal) $(set_color blue)$(status current-command)$(set_color normal) [options] on | off | status

$(set_color yellow)Arguments:$(set_color normal)
	$(set_color blue)on$(set_color normal)      Enable what-changed.fish
	$(set_color blue)off$(set_color normal)     Disable what-changed.fish
	$(set_color blue)status$(set_color normal)  Show the current status of what-changed.fish

$(set_color yellow)Options:$(set_color normal)
	$(set_color green)-h$(set_color normal), $(set_color green)--help$(set_color normal)      Show this help message and exit"

        echo $usage
        return 0
    end

    set -l argc (count $argv)
    if test $argc -eq 0
        whatchanged --help
        return 0
    end



    set -l verb $argv[1]
    switch $verb

        case on
            set WHAT_CHANGED_DISABLED 0
            source (status current-filename)
        case off
            set WHAT_CHANGED_DISABLED 1
            functions --erase _what_changed_preexec
            functions --erase _what_changed_postexec
        case status
            set -l reset (set_color normal)
            set -l color (test $WHAT_CHANGED_DISABLED -eq 1; and set_color green; or set_color red)
            printf "\$WHAT_CHANGED_DISABLED:    %s%d%s\n" $color $WHAT_CHANGED_DISABLED $reset
            set color (test $WHAT_CHANGED_VERBOSE -eq 1; and set_color green; or set_color red)
            printf "\$WHAT_CHANGED_VERBOSE:     %s%d%s\n" $color $WHAT_CHANGED_VERBOSE $reset
            set color (test $WHAT_CHANGED_USE_PREFIX -eq 1; and set_color green; or set_color red)
            printf "\$WHAT_CHANGED_USE_PREFIX:  %s%d%s\n" $color $WHAT_CHANGED_USE_PREFIX $reset
            printf "\$WHAT_CHANGED_MAXDEPTH:    %d\n" $WHAT_CHANGED_MAXDEPTH
        case "*"
            echo "Unknown verb: $verb"
            return 1
    end
end

if test $WHAT_CHANGED_DISABLED -eq 1
    return
end

function _what_changed_print_deleted_objects --argument-names deleted
    set -l deleted $argv
    if test $WHAT_CHANGED_VERBOSE -eq 1
        for it in $deleted
            set_color red
            echo "deleted file: $it"
            set_color normal
        end
    else
        set -l deleted_count (count $deleted)
        test $deleted_count -eq 0; and return
        if test $WHAT_CHANGED_USE_PREFIX -eq 1
            printf "%s " $_what_changed_echo_prefix
        end
        printf "deleted%s %d%s %s\n" \
            (set_color red) $deleted_count (set_color normal) \
            (test $deleted_count -eq 1; and echo "file"; or echo "files")
    end
end

function prompt_what_changed

end

function _what_changed_print_created_objects
    set -l created $argv
    test (count $created) -eq 0; and return
    if test $WHAT_CHANGED_VERBOSE -eq 1
        for it in $created
            set -l color
            set -l prefix
            # Test for symlinks first, because they are also files
            if test -L $it
                set color cyan
                # TODO: <kpbaks 2023-07-07 09:53:12> symlink file or symlink directory?
                set prefix "new symlink : "
            else if test -f $it
                set color green
                set prefix "new file : "
            else if test -d $it
                set color blue
                set prefix "new directory : "
            else if test -p $it
                set color yellow
                set prefix "new pipe: "
            else if test -S $it
                set color magenta
                set prefix "new socket: "
            else if test -b $it
                set color red
                set prefix "new block device: "
            else if test -c $it
                set color red
                set prefix "new character device: "
            else
                set color red
                set prefix "new unknown file type: "
                set_color red
                echo "SHOULD NOT BE POSSIBLE!"
                set_color normal
            end

            printf "%s%s%s\n" (set_color $color) $prefix $it
        end
    else
        set -l files
        set -l directories
        set -l symlinks
        set -l pipes
        set -l sockets
        set -l block_devices
        set -l character_devices

        for it in $created
            # Test for symlinks first, because they are also files
            if test -L $it
                set -a symlinks $it
            else if test -f $it
                set -a files $it
            else if test -d $it
                set -a directories $it
            else if test -p $it
                set -a pipes $it
            else if test -S $it
                set -a sockets $it
            else if test -b $it
                set -a block_devices $it
            else if test -c $it
                set -a character_devices $it
            end
        end

        set -l files_count (count $files)
        set -l directories_count (count $directories)
        set -l symlinks_count (count $symlinks)
        set -l pipes_count (count $pipes)
        set -l sockets_count (count $sockets)
        set -l block_devices_count (count $block_devices)
        set -l character_devices_count (count $character_devices)

        if test $WHAT_CHANGED_USE_PREFIX -eq 1
            printf "%s " $_what_changed_echo_prefix
        end

        printf "created "

        set -l reset (set_color normal)
        if test $files_count -gt 0
            printf "%s%d%s %s " (set_color green) $files_count $reset (test $files_count -eq 1; and echo "file"; or echo "files")
        end
        if test $directories_count -gt 0
            printf "%s%d%s %s " (set_color blue) $directories_count $reset (test $directories_count -eq 1; and echo "directory"; or echo "directories")
        end
        if test $symlinks_count -gt 0
            printf "%s%d%s %s " (set_color cyan) $symlinks_count $reset (test $symlinks_count -eq 1; and echo "symlink"; or echo "symlinks")
        end
        if test $pipes_count -gt 0
            printf "%s%d%s %s " (set_color yellow) $pipes_count $reset (test $pipes_count -eq 1; and echo "pipe"; or echo "pipes")
        end
        if test $sockets_count -gt 0
            printf "%s%d%s %s " (set_color magenta) $sockets_count $reset (test $sockets_count -eq 1; and echo "socket"; or echo "sockets")
        end
        if test $block_devices_count -gt 0
            printf "%s%d%s %s " (set_color red) $block_devices_count $reset (test $block_devices_count -eq 1; and echo "block device"; or echo "block devices")
        end
        if test $character_devices_count -gt 0
            printf "%s%d%s %s " (set_color red) $character_devices_count $reset (test $character_devices_count -eq 1; and echo "character device"; or echo "character devices")
        end

        printf "\n"
    end
end

function _what_changed_preexec --on-event fish_preexec
    test $_what_changed_last_directory != $PWD; and return # don't run if we've changed directories
    set _what_changed_directory_contents_before_command * .*
end

function _what_changed_postexec --on-event fish_postexec
    if test $_what_changed_last_directory != $PWD
        set _what_changed_last_directory $PWD
        return # don't run if we've changed directories
    end

    set -l directory_contents_after_prompt * .*
    set -l deleted
    for it in $_what_changed_directory_contents_before_command
        set -l idx (contains --index -- $it $directory_contents_after_prompt)
        if test $status -eq 0
            set -e directory_contents_after_prompt[$idx]
            continue
        end
        set -a deleted $it
    end

    _what_changed_print_deleted_objects $deleted

    # Will be empty if no files were deleted
    _what_changed_print_created_objects $directory_contents_after_prompt
end
