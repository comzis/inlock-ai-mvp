<?php
/**
 * Roundcube SMTP Configuration Override
 * Configured for Mailu with TLS_FLAVOR=notls
 * 
 * This file is mounted into the webmail container to provide
 * persistent SMTP configuration that works with notls mode.
 */

// FORCE HTTPS unconditionally for Traefik
$_SERVER['HTTPS'] = 'on';

// DISABLE IP CHECK to prevent session invalidation loops
$config['ip_check'] = false;

// SMTP server configuration
// Use 'front' container which handles mail routing
$config['smtp_server'] = 'front';
$config['smtp_port'] = 25;

// Disable SSL/TLS verification for notls mode
// This is required because we're using TLS_FLAVOR=notls
$config['smtp_conn_options'] = array(
    'ssl' => array(
        'verify_peer' => false,
        'verify_peer_name' => false,
        'allow_self_signed' => true
    ),
);

// Use user credentials for SMTP authentication
// %u = username (email), %p = password
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';

// Force File Session Storage (Redis extension missing in image)
$config['session_storage'] = 'php';
$config['session_save_path'] = '/var/www/roundcube/temp';
