from sos.report.plugins import Plugin, IndependentPlugin
class clixon(Plugin, IndependentPlugin):
    short_desc = 'clixon etc'

    def setup(self):
        self.add_copy_spec([
            "/etc/clixon/running_db",
        ])
