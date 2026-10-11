# Glob

A Glob matcher for Jai to match strings against wildcard patterns. 

It has a few desireable qualities:
* The functions read the input strings without copying them. 
* Memory use is constant and does not grow with input length.
* Functions do not allocate heap or temporary memory.


## Basic Usage
```jai
#import "Basic";
Glob :: #import "glob";

#run {
    assert(Glob.matches_path("tests/unit/math.jai", "tests/**/*.jai"));
    assert(!Glob.matches_path("tests/unit/math.jai", "tests/*.jai"));
    assert(Glob.matches("sorting/insertion", "sorting/*"));
}
```

## API

There are two available functions:

### matches:
```jai
// Treats the input as plain text. * and ? can match slashes.
matches :: (value: string, pattern: string) -> bool
```

### matches_path:
```jai
// Understands path segments. * and ? cannot match separators. A whole ** segment can match zero or more folders.
matches_path :: (path: string, pattern: string) -> bool
```

## Supported syntax

These rules apply to `matches_path`:

| Syntax | Meaning |
| --- | --- |
| `?` | One byte within a path segment. |
| `*` | Any sequence of bytes within a path segment, including an empty sequence. |
| `**` | Zero or more path segments. It must occupy an entire segment. |
| `a**b`, `***` | Consecutive stars act like a single `*`. They do not cross separators. |
| `/`, `\` | Equivalent path separators on every platform. |
| `[ab]`, `[a-z]`, `[!ab]` | Plain text. Brackets do not define character classes or ranges. |
| `{a,b}` | Plain text. Braces do not define alternatives. |
| `!` | A literal byte, including at the start of a pattern. It does not negate a match. |
| `@(a)`, `+(a)` | Plain text. Parentheses do not define extended glob operators. |

Brackets, braces, and parentheses do not disable wildcards inside them. For example, `[?]` matches `[a]` because `?` remains a wildcard.

For `matches`, `/` and `\` are ordinary, distinct bytes. Both wildcards can match separators. Repeated `*` bytes act like one `*`, with no separate rule for `**`.

Glob has no escape syntax for a literal `*` or `?`. Jai string literals still use Jai's normal escapes.

## Validation

Neither function has a separate validation call or returns any error description. `false` can mean either that the input failed a path check or did not match.

`matches_path` first removes repeated leading `./` or `.\` segments from both the path and the pattern. If either input has one of these forms, `matches_path` returns `false`:

- An empty string.
- A string that starts or ends with a separator.
- A string with adjacent separators, including a mix of `/` and `\`.

The matcher does not resolve `.` and `..` or drive prefixes such as `C:`. It does not apply operating-system rules for absolute paths or file names.

`matches` accepts empty inputs and does not check separators. An empty value matches an empty pattern or `*`, but does not match `?`.

Unclosed brackets and braces will not cause syntax errors. Neither function reads the filesystem or checks whether a file exists.

## Examples

| Function | Value | Pattern | Result |
| --- | --- | --- | --- |
| `matches_path` | `root.jai` | `**/*.jai` | `true` |
| `matches_path` | `src/math.jai` | `*.jai` | `false` |
| `matches_path` | `src` | `src/**` | `true` |
| `matches_path` | `a/b` | `a?b` | `false` |
| `matches` | `a/b` | `a?b` | `true` |
| `matches_path` | `./src/math.jai` | `src/*.jai` | `true` |
| `matches_path` | `src//math.jai` | `**/*.jai` | `false` |
| `matches_path` | `.hidden.jai` | `*.jai` | `true` |
| `matches_path` | `file[1].jai` | `file[1].jai` | `true` |
| `matches_path` | `file1.jai` | `file[1].jai` | `false` |

## Import

Add the directory that contains `glob` to Jai's module search path. Or import the module file directly:

```jai
Glob :: #import,file "/path/to/glob/module.jai";
```

## Tests

Run the tests from this directory:

```sh
jai tests/run.jai
```

The tests check the results and require zero allocations. They run at compile time and produce no executable.

## Future
Some things I'd like to add in the future:
- Validation
- Proper filesystem support
- Better handling of cross platform stuff

## Inspiration

The algorithm has in Glob uses retry positions with no recursion or allocated state table. Ideas are  borrowed from [fast-glob](https://github.com/oxc-project/fast-glob/blob/main/src/lib.rs).
