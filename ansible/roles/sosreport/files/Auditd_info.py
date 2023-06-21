from sos.report.plugins import Plugin, IndependentPlugin
from datetime import datetime
class Auditd_info(Plugin, IndependentPlugin):
    short_desc = 'Auditd info information'

    def setup(self):
        aureport_cmd="aureport --tty"
        start_opt = " -ts %s"
        since=None
        start=None
        if self.get_option('since'):
            since = self.get_option('since')
            start = since.strftime("%m/%d/%y %H:%M:%S")
            aureport_cmd+=start_opt % start
        self.add_cmd_output([
            aureport_cmd,
        ])
