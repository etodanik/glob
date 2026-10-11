Glob :: #import,file "../module.jai";
#import "Basic";
#import "Compiler";

// Run with: jai tests/run.jai
#run {
    set_build_options_dc(.{do_output = false});

    Match_Kind :: enum { PATH; TEXT; }
    Glob_Case :: struct {
        value: string;
        pattern: string;
        expected: bool;
        kind: Match_Kind;
    }

    cases := Glob_Case.[
        .{"root.spec.jai", "**/*.spec.jai", true, .PATH},
        .{"nested/deeper/file.spec.jai", "**/*.spec.jai", true, .PATH},
        .{"nested/file.jai", "**/*.spec.jai", false, .PATH},
        .{"nested/file.spec.jai.bak", "**/*.spec.jai", false, .PATH},
        .{"root.spec.jai", "*.spec.jai", true, .PATH},
        .{"nested/file.spec.jai", "*.spec.jai", false, .PATH},
        .{"tests/file.jai", "tests/*.jai", true, .PATH},
        .{"tests/nested/file.jai", "tests/*.jai", false, .PATH},
        .{"tests/file.jai", "tests/**/*.jai", true, .PATH},
        .{"tests/nested/file.jai", "tests/**/*.jai", true, .PATH},
        .{"other/tests/file.jai", "tests/**/*.jai", false, .PATH},
        .{"tests/file.jai", "tests/**/file.jai", true, .PATH},
        .{"tests/a/b/file.jai", "tests/**/file.jai", true, .PATH},
        .{"tests/a/file.jai", "tests/**", true, .PATH},
        .{"anything/a.txt", "**/*", true, .PATH},
        .{"root.txt", "**/*", true, .PATH},
        .{"a/b/file.jai", "**/**/file.jai", true, .PATH},
        .{"file.jai", "**/**/file.jai", true, .PATH},
        .{"x/a/y/a/z/a/file.jai", "**/a/**/a/**/a/*.jai", true, .PATH},
        .{"x/a/y/a/z/file.jai", "**/a/**/a/**/a/*.jai", false, .PATH},
        .{"a/b/x/a/b/file.jai", "**/a/b/*.jai", true, .PATH},
        .{"a/b/x/a/b/file.txt", "**/a/b/*.jai", false, .PATH},
        .{"a/b/c/x/b/c/file.jai", "a/**/b/c/*.jai", true, .PATH},
        .{"a/b/c/x/b/c/file.txt", "a/**/b/c/*.jai", false, .PATH},
        .{"a/x/b/y/c/x/b/y/c/end.jai", "**/a/**/b/y/c/end.jai", true, .PATH},
        .{"a/x/b/y/c/x/b/y/c/end.txt", "**/a/**/b/y/c/end.jai", false, .PATH},
        .{"a/b/c", "a/**/b/**/c/**", true, .PATH},
        .{"a/b", "a/**/b/**/**", true, .PATH},
        .{"a/b", "a/**/b/**/c", false, .PATH},
        .{"a/b/c", "**/a/**/b/**", true, .PATH},
        .{"tests/unit_1.jai", "tests/unit_?.jai", true, .PATH},
        .{"tests/unit_12.jai", "tests/unit_?.jai", false, .PATH},
        .{"tests/unit_.jai", "tests/unit_?.jai", false, .PATH},
        .{"tests/unit_/1.jai", "tests/unit_?.jai", false, .PATH},
        .{"ab_cd_ef.jai", "a*_e*.jai", true, .PATH},
        .{"ab_cd_ef.jai", "a*_e*.spec.jai", false, .PATH},
        .{"name.jai", "na**me.jai", true, .PATH},
        .{"na/a/me.jai", "na**me.jai", false, .PATH},
        .{"exact.jai", "exact.jai", true, .PATH},
        .{"Exact.jai", "exact.jai", false, .PATH},
        .{".hidden.spec.jai", "**/*.spec.jai", true, .PATH},
        .{"tests\\nested\\file.jai", "tests/**/*.jai", true, .PATH},
        .{"tests/nested/file.jai", "tests\\**\\*.jai", true, .PATH},
        .{"./tests/file.jai", "./tests/**/*.jai", true, .PATH},
        .{".\\tests\\file.jai", "././tests/*.jai", true, .PATH},
        .{"file[1].jai", "file[1].jai", true, .PATH},
        .{"file1.jai", "file[1].jai", false, .PATH},
        .{"", "**", false, .PATH},
        .{"file.jai", "", false, .PATH},
        .{"/file.jai", "**/*.jai", false, .PATH},
        .{"file.jai", "/**/*.jai", false, .PATH},
        .{"tests/file.jai", "tests//*.jai", false, .PATH},
        .{"tests//file.jai", "tests/**/*.jai", false, .PATH},
        .{"tests/file.jai", "tests/**/", false, .PATH},
        .{"tests//file.jai", "**", false, .PATH},
        .{"tests/file.jai", "**//**", false, .PATH},
        // These patterns have many possible '*' matches. Matching must not explore every combination.
        .{"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.jai", "*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*z.jai", false, .PATH},
        .{"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.jai", "*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*.jai", true, .PATH},
        .{"a/b", "a?b", false, .PATH},
        .{"a/x/b", "a*b", false, .PATH},
        .{"*literal", "*", true, .PATH},
        .{"*xa", "*a", true, .PATH},

        // Text matching treats slashes as ordinary bytes.
        .{"abfoo1", "*foo?", true, .TEXT},
        .{"axybzc", "a*b*c", true, .TEXT},
        .{"", "", true, .TEXT},
        .{"", "*", true, .TEXT},
        .{"", "?", false, .TEXT},
        .{"*literal", "*", true, .TEXT},
        .{"*xa", "*a", true, .TEXT},
        .{"?", "?", true, .TEXT},
        .{"?x", "?", false, .TEXT},
        .{"foobar", "foo", false, .TEXT},
        .{"a/b", "a?b", true, .TEXT},
        .{"a/x/b", "a*b", true, .TEXT},
        .{"a\\b", "a?b", true, .TEXT},
        .{"a//b", "*", true, .TEXT},
        .{"./a", "a", false, .TEXT},
        // Each '?' matches one byte. A two-byte UTF-8 character requires '??'.
        .{"é", "?", false, .TEXT},
        .{"é", "??", true, .TEXT},
    ];

    for cases {
        allocations: Glob_Allocations;
        allocations.allocator = context.allocator;
        actual: bool;
        {
            push_allocator(count_glob_allocations, *allocations);
            // Without temporary storage, the Basic temporary allocator uses the context allocator.
            // The counter records each allocation, even if the matcher later frees the memory.
            old_temporary_storage := context.temporary_storage;
            context.temporary_storage = null;
            defer context.temporary_storage = old_temporary_storage;
            if it.kind == .PATH actual = Glob.matches_path(it.value, it.pattern);
            else actual = Glob.matches(it.value, it.pattern);
        }
        assert(allocations.count == 0, "% '%' against '%' allocated % times.", it.kind, it.value, it.pattern, allocations.count);
        assert(actual == it.expected, "% '%' against '%' expected %, got %.", it.kind, it.value, it.pattern, it.expected, actual);
    }
    print("Passed % glob tests.\n", cases.count);
}

Glob_Allocations :: struct {
    allocator: Allocator;
    count: s64;
}

count_glob_allocations :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
    allocations := cast(*Glob_Allocations) allocator_data;
    if mode == .ALLOCATE || mode == .RESIZE allocations.count += 1;
    allocator := allocations.allocator;
    return allocator.proc(mode, size, old_size, old_memory, allocator.data);
}
