from sos.report.plugins import Plugin, IndependentPlugin
class k3s(Plugin, IndependentPlugin):
    short_desc = 'k3s information'

    def setup(self):
        self.add_cmd_output([
            "kubectl get pod -A",
            "kubectl get pod -A -o yaml"
        ])
        self.add_copy_spec([
            "/var/log/telegraf",
            "/var/log/traffic-engine",
            "/var/log/tsg-diagnose"
        ])
