<script>
    $(document).ready(function() {
        updateServiceControlUI('metricsexporter');

        function escapeHtml(str) {
            return $('<span>').text(str).html();
        }

        function statusLabel(status) {
            switch (status) {
                case 'none':
                    return '<span class="label label-success">Online</span>';
                case 'down':
                case 'force_down':
                    return '<span class="label label-danger">Offline</span>';
                case 'loss':
                    return '<span class="label label-warning">Packetloss</span>';
                case 'delay':
                    return '<span class="label label-warning">Latency</span>';
                case 'delay+loss':
                    return '<span class="label label-warning">Latency, Packetloss</span>';
                default:
                    return '<span class="label label-default">Pending</span>';
            }
        }

        function renderGatewayCollector(collector) {
            var html = '<h3>' + escapeHtml(collector.name) + '</h3>';
            html += '<table class="table table-striped table-condensed">';
            html += '<thead><tr>' +
                '<th>{{ lang._("Gateway") }}</th>' +
                '<th>{{ lang._("Description") }}</th>' +
                '<th>{{ lang._("Status") }}</th>' +
                '<th>{{ lang._("Delay") }}</th>' +
                '<th>{{ lang._("Stddev") }}</th>' +
                '<th>{{ lang._("Loss") }}</th>' +
                '<th>{{ lang._("Monitor") }}</th>' +
                '</tr></thead><tbody>';

            if (collector.rows && collector.rows.length > 0) {
                $.each(collector.rows, function(idx, gw) {
                    html += '<tr>' +
                        '<td>' + escapeHtml(gw.name) + '</td>' +
                        '<td>' + escapeHtml(gw.description) + '</td>' +
                        '<td>' + statusLabel(gw.status) + '</td>' +
                        '<td>' + escapeHtml(gw.delay !== '~' ? gw.delay : '-') + '</td>' +
                        '<td>' + escapeHtml(gw.stddev !== '~' ? gw.stddev : '-') + '</td>' +
                        '<td>' + escapeHtml(gw.loss !== '~' ? gw.loss : '-') + '</td>' +
                        '<td>' + escapeHtml(gw.monitor) + '</td>' +
                        '</tr>';
                });
            } else {
                html += '<tr><td colspan="7">{{ lang._("No data available.") }}</td></tr>';
            }

            html += '</tbody></table>';
            return html;
        }

        function renderGenericCollector(collector) {
            var html = '<h3>' + escapeHtml(collector.name) + '</h3>';
            html += '<table class="table table-striped table-condensed">';

            if (collector.rows && collector.rows.length > 0) {
                // Build header from keys of first row
                var keys = Object.keys(collector.rows[0]);
                html += '<thead><tr>';
                $.each(keys, function(i, key) {
                    html += '<th>' + escapeHtml(key) + '</th>';
                });
                html += '</tr></thead><tbody>';

                $.each(collector.rows, function(idx, row) {
                    html += '<tr>';
                    $.each(keys, function(i, key) {
                        html += '<td>' + escapeHtml(String(row[key] || '')) + '</td>';
                    });
                    html += '</tr>';
                });
            } else {
                html += '<tbody>';
                html += '<tr><td>{{ lang._("No data available.") }}</td></tr>';
            }

            html += '</tbody></table>';
            return html;
        }

        function loadStatus() {
            $("#btnRefreshProgress").addClass("fa-spinner fa-pulse");
            ajaxCall("/api/metricsexporter/status/collector", {}, function(data, status) {
                $("#collectorsContent").empty();
                if (status === "success" && data['collectors'] !== undefined) {
                    if (data['collectors'].length === 0) {
                        $("#collectorsContent").html(
                            '<p class="text-muted">{{ lang._("No collectors are enabled. Enable collectors in Settings.") }}</p>'
                        );
                    } else {
                        $.each(data['collectors'], function(idx, collector) {
                            var html;
                            if (collector.type === 'gateway') {
                                html = renderGatewayCollector(collector);
                            } else {
                                html = renderGenericCollector(collector);
                            }
                            $("#collectorsContent").append(html);
                        });
                    }
                    if (data['node_exporter_installed'] === false) {
                        $("#node_exporter_warning").show();
                    }
                } else {
                    $("#collectorsContent").html(
                        '<p>{{ lang._("Unable to fetch collector status. Is the exporter running?") }}</p>'
                    );
                }
                $("#btnRefreshProgress").removeClass("fa-spinner fa-pulse");
            });
        }

        $("#btnRefresh").click(function(event) {
            event.preventDefault();
            loadStatus();
        });

        loadStatus();
    });
</script>

<div class="alert alert-warning" role="alert" id="node_exporter_warning" style="display:none;">
    <b>{{ lang._('Warning:') }}</b>
    {{ lang._('The Prometheus Exporter plugin (os-node_exporter) is not installed. The metrics exporter writes metrics to the node_exporter textfile collector directory, which requires os-node_exporter to be installed and enabled.') }}
</div>

<div class="content-box">
    <div id="collectorsContent">
    </div>
    <div class="pull-right" style="padding: 10px;">
        <button class="btn btn-primary" id="btnRefresh" type="button">
            <b>{{ lang._('Refresh') }}</b>
            <span id="btnRefreshProgress" class="fa fa-refresh"></span>
        </button>
    </div>
    <div class="clearfix"></div>
</div>
