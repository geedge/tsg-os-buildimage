from sos.report.plugins import Plugin, IndependentPlugin
class mrzcpd(Plugin, IndependentPlugin):
    short_desc = 'mrzcpd info information'

    def setup(self):
        self.add_copy_spec([
            "/opt/tsg/mrzcpd/etc",
            "/var/run/mrzcpd/hwfile.json",
            "/var/run/mrzcpd/mrmonit*",
        ])
