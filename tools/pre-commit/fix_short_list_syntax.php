<?php

declare(strict_types=1);

if ($argc < 2) {
    fwrite(STDERR, "Usage: php fix_short_list_syntax.php <file>\n");
    exit(1);
}

$file_path = $argv[1];
$contents = file_get_contents($file_path);

if ($contents === false) {
    fwrite(STDERR, "Cannot read file: {$file_path}\n");
    exit(1);
}

$tokens = token_get_all($contents);
$has_list_syntax = false;

foreach ($tokens as $token) {
    if (!is_array($token)) {
        continue;
    }

    [$token_id, , $line] = $token;

    if ($token_id !== T_LIST) {
        continue;
    }

    fwrite(STDERR, "{$file_path}:{$line} Use [] destructuring instead of list().\n");
    $has_list_syntax = true;
}

if ($has_list_syntax) {
    exit(1);
}
