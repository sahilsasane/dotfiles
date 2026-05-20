"""Custom Kitty tab bar using the built-in separator renderer.

This keeps mouse handling and sizing behavior sane while only customizing the
title content to show the basename of the active working directory.
"""

from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, draw_tab_with_separator


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    new_draw_data = draw_data._replace(
        title_template=" {tab.active_wd.rsplit('/', 1)[-1] or '/'} ",
        active_title_template=" {tab.active_wd.rsplit('/', 1)[-1] or '/'} ",
    )
    return draw_tab_with_separator(
        new_draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
    )
