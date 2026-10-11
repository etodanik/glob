// Matches `value` against a glob `pattern` treating `value` as a string.
// This function does not understand path separators and treats `value` as plain text. * and ? can match slashes.
// @return `bool` false for invalid inputs or no match. There is no validation attempted, so an invalid input will return
// false just like a valid `value` with no match.
matches :: (value: string, pattern: string) -> bool {
    p, v: s64;
    star: s64 = -1;
    retry: s64;
    while v < value.count {
        if p < pattern.count && pattern[p] == #char "*" {
            star = p; p += 1; retry = v;
        } else if p < pattern.count && (pattern[p] == value[v] || pattern[p] == #char "?") {
            p += 1; v += 1;
        } else if star >= 0 {
            retry += 1; v = retry; p = star + 1;
        } else return false;
    }
    while p < pattern.count && pattern[p] == #char "*" p += 1;
    return p == pattern.count;
}

// Matches `path` against a glob `pattern` treating `path` as a path string.
// Understands path segments separated via forward or backward slashes. * and ? cannot match separators.
// A whole ** segment can match zero or more folders.
// @return `bool` false for invalid inputs or no match. There is no validation attempted, so an invalid input will return
// false just like a valid `path` with no match.
matches_path :: (path: string, pattern: string) -> bool {
    relative_path := strip_current_directory(path);
    relative_pattern := strip_current_directory(pattern);
    if !valid_path(relative_path) || !valid_path(relative_pattern) return false;

    path_offset: s64;
    pattern_offset: s64;
    globstar_pattern: s64 = -1;
    globstar_path: s64;
    while path_offset < relative_path.count {
        next_pattern := pattern_offset;
        segment := next_segment(relative_pattern, *next_pattern);
        if segment == "**" {
            // If the first attempt matches zero segments. A trailing ** accepts the remaining path.
            if next_pattern == relative_pattern.count return true;
            pattern_offset = next_pattern;
            globstar_pattern = next_pattern;
            globstar_path = path_offset;
            continue;
        }

        next_path := path_offset;
        name := next_segment(relative_path, *next_path);
        if segment.count && matches(name, segment) {
            path_offset = next_path;
            pattern_offset = next_pattern;
            continue;
        }

        if globstar_pattern < 0 || globstar_path == relative_path.count return false;
        // Each retry extends the latest ** match by one whole path segment.
        next_segment(relative_path, *globstar_path);
        path_offset = globstar_path;
        pattern_offset = globstar_pattern;
    }

    // After the path ends, the remaining pattern can contain only '**' segments.
    while pattern_offset < relative_pattern.count {
        if next_segment(relative_pattern, *pattern_offset) != "**" return false;
    }
    return true;
}

#scope_file

is_separator :: (character: u8) -> bool {
    return character == #char "/" || character == #char "\\";
}

valid_path :: (text: string) -> bool {
    if !text.count || is_separator(text[0]) || is_separator(text[text.count - 1]) return false;
    previous_separator := false;
    for character: text {
        separator := is_separator(character);
        if separator && previous_separator return false;
        previous_separator = separator;
    }
    return true;
}

strip_current_directory :: (text: string) -> string {
    result := text;
    while result.count >= 2 && result[0] == #char "." && is_separator(result[1]) {
        result = slice(result, 2, result.count - 2);
    }
    return result;
}

next_segment :: (text: string, offset: *s64) -> string {
    start := offset.*;
    while offset.* < text.count && !is_separator(text[offset.*]) offset.* += 1;
    result := slice(text, start, offset.* - start);
    if offset.* < text.count offset.* += 1;
    return result;
}

#import "String";
