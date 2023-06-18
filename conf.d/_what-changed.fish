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
set -g WHAT_CHANGED_DISABLED 0
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

    end
    if test $WHAT_CHANGED_DISABLED -eq 1
        set -g WHAT_CHANGED_DISABLED 1
    else
        set -g WHAT_CHANGED_DISABLED 0
    end
end

function _what_changed_on_PWD_update --on-variable PWD
    set _what_changed_last_directory $PWD
end

function _what_changed_preexec --on-event fish_preexec
    test $WHAT_CHANGED_DISABLED -eq 1; and return
    test $_what_changed_last_directory = $PWD; or return # don't run if we've changed directories
    set _what_changed_directory_contents_before_command # clear it
    for it in * .*
        set -a _what_changed_directory_contents_before_command $it
    end
end

function _what_changed_postexec --on-event fish_postexec
    test $WHAT_CHANGED_DISABLED -eq 1; and return
    test $_what_changed_last_directory = $PWD; or return # don't run if we've changed directories
    set -l directory_contents_after_command
    for it in * .*
        set -a directory_contents_after_command $it
    end
    for it in $_what_changed_directory_contents_before_command
        contains -- $it $directory_contents_after_command; and continue
        echo "deleted file: $it"
    end
end
