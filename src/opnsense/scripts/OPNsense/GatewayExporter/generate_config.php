#!/usr/local/bin/php
<?php

/*
 * Copyright (C) 2026 Brendan Bank
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Generate gateway exporter config file from OPNsense model/config.
 * Runs as root via configd before starting the unprivileged daemon.
 */

require_once 'config.inc';
require_once 'util.inc';
require_once 'interfaces.inc';

$mdl = new \OPNsense\GatewayExporter\GatewayExporter();

$interval = (int)$mdl->interval->__toString();
if ($interval < 5 || $interval > 300) {
    $interval = 15;
}

$outputpath = $mdl->outputpath->__toString();
if (empty($outputpath) || strpos($outputpath, '..') !== false) {
    $outputpath = '/var/tmp/node_exporter/gateway.prom';
}

$config = [
    'interval' => $interval,
    'outputpath' => $outputpath,
    'gateways' => [],
];

// Cache gateway configuration so the daemon doesn't need config.xml access
$gateways = (new \OPNsense\Routing\Gateways())->gatewaysIndexedByName();
foreach ($gateways as $name => $gw) {
    $config['gateways'][$name] = [
        'description' => !empty($gw['descr']) ? $gw['descr'] : $name,
        'monitor' => $gw['monitor'] ?? '',
        'force_down' => !empty($gw['force_down']),
        'monitor_disable' => !empty($gw['monitor_disable']),
        'latencyhigh' => isset($gw['current_latencyhigh']) ? (float)$gw['current_latencyhigh'] : null,
        'latencylow' => isset($gw['current_latencylow']) ? (float)$gw['current_latencylow'] : null,
        'losshigh' => isset($gw['current_losshigh']) ? (float)$gw['current_losshigh'] : null,
        'losslow' => isset($gw['current_losslow']) ? (float)$gw['current_losslow'] : null,
    ];
}

// Write config file (readable by unprivileged daemon)
$config_path = '/usr/local/etc/gateway_exporter.conf';
file_put_contents($config_path, json_encode($config, JSON_PRETTY_PRINT) . "\n");
chmod($config_path, 0644);

// Ensure output directory exists and is writable by the daemon (runs as nobody)
$output_dir = dirname($outputpath);
if (!is_dir($output_dir)) {
    mkdir($output_dir, 01777, true);
} else {
    // Ensure the daemon can write to the directory
    $perms = fileperms($output_dir);
    if (($perms & 0002) === 0) {
        chmod($output_dir, $perms | 0003);
    }
}
