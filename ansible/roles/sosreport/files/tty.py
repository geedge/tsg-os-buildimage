from sos.report.plugins import Plugin, IndependentPlugin

class TTY(Plugin, IndependentPlugin):
    short_desc = 'TTY information'

    def setup(self):
        self.add_cmd_output([
            "aureport --tty",
            "tty_info"
        ])
        
