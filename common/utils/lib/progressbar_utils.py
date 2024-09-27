import progressbar as bar
import sys


def disable_widgets_if_not_interactive(kwargs):
    if not (sys.stdout.isatty() and sys.stderr.isatty()):
        # Disable all widgets if non-interactive
        print('No progressbar disabled because non-interactive terminal.')
        kwargs['widgets'] = []


def progressbar(*args, **kwargs):
    disable_widgets_if_not_interactive(kwargs)
    b = bar.progressbar(*args, **kwargs)

    return b


class ProgressBar(bar.ProgressBar):
    def __init__(self, *args, **kwargs):
        disable_widgets_if_not_interactive(kwargs)
        super().__init__(*args, **kwargs)
