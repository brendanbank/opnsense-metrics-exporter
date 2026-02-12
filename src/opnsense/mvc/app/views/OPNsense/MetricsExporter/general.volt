<script>
    $(document).ready(function() {
        var data_get_map = {'frm_general_settings':"/api/metricsexporter/general/get"};
        mapDataToFormUI(data_get_map).done(function(data) {
            formatTokenizersUI();
            $('.selectpicker').selectpicker('refresh');
        });

        updateServiceControlUI('metricsexporter');

        // Load available collectors and render checkboxes
        ajaxCall("/api/metricsexporter/general/collectors", {}, function(data, status) {
            if (status === "success" && data['collectors']) {
                var container = $("#collectorsContainer");
                container.empty();
                $.each(data['collectors'], function(idx, col) {
                    var checked = col.enabled ? ' checked="checked"' : '';
                    var row = '<div class="form-group">' +
                        '<label class="col-md-3 control-label">' +
                        $('<span>').text(col.name).html() +
                        '</label>' +
                        '<div class="col-md-5">' +
                        '<input type="checkbox" class="collector-toggle" ' +
                        'data-type="' + $('<span>').text(col.type).html() + '"' +
                        checked + ' />' +
                        '</div></div>';
                    container.append(row);
                });
            }
        });

        ajaxCall("/api/metricsexporter/status/collector", {}, function(data, status) {
            if (status === "success" && data['node_exporter_installed'] === false) {
                $("#node_exporter_warning").show();
            }
        });

        $("#saveAct").click(function() {
            saveFormToEndpoint("/api/metricsexporter/general/set", 'frm_general_settings', function() {
                // Gather collector states
                var collectors = {};
                $(".collector-toggle").each(function() {
                    var type = $(this).data('type');
                    collectors[type] = $(this).is(':checked') ? 1 : 0;
                });

                // Save collector states
                ajaxCall("/api/metricsexporter/general/saveCollectors", {'collectors': collectors}, function() {
                    $("#saveAct_progress").addClass("fa fa-spinner fa-pulse");
                    ajaxCall("/api/metricsexporter/service/reconfigure", {}, function(data, status) {
                        updateServiceControlUI('metricsexporter');
                        $("#saveAct_progress").removeClass("fa fa-spinner fa-pulse");
                    });
                });
            });
        });
    });
</script>

<div class="alert alert-warning" role="alert" id="node_exporter_warning" style="display:none;">
    <b>{{ lang._('Warning:') }}</b>
    {{ lang._('The Prometheus Exporter plugin (os-node_exporter) is not installed. The metrics exporter writes metrics to the node_exporter textfile collector directory, which requires os-node_exporter to be installed and enabled.') }}
</div>

<div class="content-box" style="padding-bottom: 1.5em;">
    {{ partial("layout_partials/base_form", ['fields':generalForm,'id':'frm_general_settings']) }}

    <div class="col-md-12">
        <hr />
        <h2>{{ lang._('Collectors') }}</h2>
    </div>
    <div id="collectorsContainer" class="col-md-12">
        <div class="text-muted">{{ lang._('Loading collectors...') }}</div>
    </div>

    <div class="col-md-12">
        <hr />
        <button class="btn btn-primary" id="saveAct" type="button"><b>{{ lang._('Save') }}</b> <i id="saveAct_progress"></i></button>
    </div>
</div>
