<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

$config['db_host'] = 'mariadb';
$config['db_name'] = 'cscart';
$config['db_user'] = 'root';
$config['db_password'] = 'root';

// Host and directory where software is installed on no-secure server
$config['http_host'] = '[domain]';
$config['http_path'] = '';

// Host and directory where software is installed on secure server
$config['https_host'] = '[domain]';
$config['https_path'] = '';
$config['cache_backend'] = 'database';
$config['session_backend'] = 'database';

define('DEBUG_MODE', true); //DEBUG mode was commented out due to the security risks, which debug panel can provide to unathorized third parties, which are masking their IP address headers. Uncomment at your own resposibility.

define('DEVELOPMENT', true);

error_reporting(E_ALL);
ini_set('display_errors', 'on');
ini_set('display_startup_errors', true);

$config['tweaks']['disable_block_cache'] = true;
$config['tweaks']['dev_js'] = true;
@ini_set('memory_limit', '2048M');
$path = dirname(__FILE__) . '/error_log';
ini_set('log_errors', 'On');
ini_set('error_log', $path);

function _logWrite() {
    $messages = func_get_args();
    $i = 0;
    foreach ($messages as $message) {
        if(is_object($message)) {
            $message = (array) $message;
        }
        if (is_array($message)) {
            if(end($message) == 'var_dump') {
                unset($message[key($message)]);
                reset($message);
                ob_start();
                var_dump($message);
                $message = ob_get_contents();
                ob_end_clean();
            } else {
                $message = var_export($message, TRUE);
            }
        }
        $messages[$i] = str_replace("\n\n", "\n", $message);
        $i++;
    }

    $t = \DateTime::createFromFormat('U.u', number_format(microtime(true), 6, '.', ''));
    $ts = $t->format("m-d-Y H:i:s.u");
    $dt = date("Y-m-d_H:i");
    $logFile = dirname(__FILE__) . "/var/debug_" . $dt . ".log";

    $logMessage = "";
    foreach ($messages as $message) {
        $logMessage .= " $message \n";
    }
    $logText = "[$ts] <" . $_SERVER["REQUEST_URI"] . ">$logMessage \n";

    if ($fd = fopen ($logFile, "a+")) {
        if (flock($fd, LOCK_EX)) {
            // do an exclusive lock
            fwrite($fd, $logText);
            flock($fd, LOCK_UN); // release the lock
        } else {
            echo "Couldn't lock the file !";
            exit;
        }

        fclose($fd);
        chmod($logFile, 0666);
    }
}
