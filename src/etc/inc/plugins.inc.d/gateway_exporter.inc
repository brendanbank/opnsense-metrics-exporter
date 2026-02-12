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

function gateway_exporter_services()
{
    $services = array();
    $mdl = new \OPNsense\GatewayExporter\GatewayExporter();

    if ($mdl->enabled->__toString() == "0") {
        return $services;
    }

    $services[] = array(
        'description' => gettext('Gateway Exporter'),
        'configd' => array(
            'restart' => array('gateway_exporter restart'),
            'start' => array('gateway_exporter start'),
            'stop' => array('gateway_exporter stop'),
        ),
        'name' => 'gateway_exporter',
        'pidfile' => '/var/run/gateway_exporter.pid',
    );

    return $services;
}

function gateway_exporter_configure()
{
    return [
        'bootup' => ['gateway_exporter_start:0'],
    ];
}

function gateway_exporter_syslog()
{
    return [
        'gateway_exporter' => ['facility' => ['gateway_exporter']],
    ];
}

function gateway_exporter_start()
{
    $mdl = new \OPNsense\GatewayExporter\GatewayExporter();

    if ($mdl->enabled->__toString() == "1") {
        configd_run('gateway_exporter start');
    }
}
