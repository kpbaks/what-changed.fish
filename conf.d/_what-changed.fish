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
set -g WHAT_CHANGED_DISABLED 0
# _what_changed_ is used as a namespace prefix for variables, to avoid collisions
set -g _what_changed_directory_contents_before_command
set -g _what_changed_last_directory $PWD

function whatchanged
    set -l argc (count $argv)
    if test $argc -eq 0
        return
    end


    set -l verb $argv[1]
    switch $verb

        case on
            set WHAT_CHANGED_DISABLED 0
        case off
            set WHAT_CHANGED_DISABLED 1
        case status
            echo "WHAT_CHANGED_DISABLED: $WHAT_CHANGED_DISABLED"
            echo "WHAT_CHANGED_MAXDEPTH: $WHAT_CHANGED_MAXDEPTH"
            echo "WHAT_CHANGED_VERBOSE: $WHAT_CHANGED_VERBOSE"

    end
    if test $WHAT_CHANGED_DISABLED -eq 1
        set -g WHAT_CHANGED_DISABLED 1
    else
        set -g WHAT_CHANGED_DISABLED 0
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
        if test $deleted_count -gt 0
            set_color red
            echo "deleted $deleted_count files"
            set_color normal
        end
    end
end

function prompt_what_changed

end

function _what_changed_print_created_objects
    set -l created $argv
    if test $WHAT_CHANGED_VERBOSE -eq 1
        for it in $created
            set -l color
            set -l prefix
            if test -f $it
                set color green
                set prefix "new : "
            else if test -d $it
                set color blue
                set prefix "new : "
            else if test -L $it
                set color cyan
                # TODO: <kpbaks 2023-07-07 09:53:12> symlink file or symlink directory?
                set prefix "new : "
            else if test -p $it
                set color yellow
                set prefix "new 󰟦: "
            else if test -S $it
                set color magenta
                # 󱄇
                set prefix "new socket: "
            else if test -b $it
                set color red
                set prefix "new block device: "

            else if test -c $it
                set color red
                set prefix "new character device: "
            else
                echo "new unknown file type: $it"
                set_color red
                echo "SHOULD NOT BE POSSIBLE!"
                set_color normal
            end

            printf "%s%s%s\n" (set_color $color) $prefix $it
        end
    else
        set -l created_count (count $created)
        set -l postfix (test $created_count -eq 1; and echo "file"; or echo "files")
        if test $created_count -gt 0
            set_color green
            echo "created $created_count $postfix"
            set_color normal
        end
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
