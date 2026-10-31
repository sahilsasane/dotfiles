"""Hook state transitions and status rendering, without tmux or agents."""
import importlib.util
from pathlib import Path
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/agent-status.py'
spec = importlib.util.spec_from_file_location('agent_status', SCRIPT)
agent = importlib.util.module_from_spec(spec)
spec.loader.exec_module(agent)


def run(*events, now=100):
    state = {}
    for event in events:
        state = agent.apply(state, event, now)
    return state


class ApplyTests(unittest.TestCase):
    def test_tool_call_shows_tool_and_command(self):
        state = run({'hook_event_name': 'UserPromptSubmit'},
                    {'hook_event_name': 'PreToolUse', 'tool_name': 'Bash', 'tool_input': {'command': '/usr/bin/git status'}})
        self.assertEqual((state['phase'], state['since']), ('Bash git', '100'))

    def test_stop_and_interrupt_return_to_idle(self):
        busy = {'hook_event_name': 'UserPromptSubmit'}
        self.assertEqual(run(busy, {'hook_event_name': 'Stop'})['phase'], '')
        self.assertEqual(run(busy, {'hook_event_name': 'PostToolUseFailure', 'is_interrupt': True})['phase'], '')

    def test_subagents_count_and_do_not_change_phase(self):
        state = run({'hook_event_name': 'UserPromptSubmit'},
                    {'hook_event_name': 'SubagentStart'}, {'hook_event_name': 'SubagentStart'},
                    {'hook_event_name': 'PreToolUse', 'tool_name': 'Read', 'agent_id': 'a1'},
                    {'hook_event_name': 'SubagentStop'})
        self.assertEqual((state['subagents'], state['phase']), ('1', 'thinking'))

    def test_question_and_idle_notification(self):
        asking = run({'hook_event_name': 'UserPromptSubmit'}, {'hook_event_name': 'PreToolUse', 'tool_name': 'AskUserQuestion'})
        self.assertEqual(asking['phase'], agent.WAITING)
        self.assertNotIn('phase', run({'hook_event_name': 'Notification'}))


class LineTests(unittest.TestCase):
    def test_busy_idle_with_shells_and_orphans(self):
        panes = [('C', 'main:1', {'pid': '10', 'phase': 'Bash git', 'since': '0', 'subagents': '2'}),
                 ('X', 'work:2', {'pid': '20', 'phase': '', 'since': '', 'subagents': ''}),
                 ('X', 'idle:3', {'pid': '30', 'phase': '', 'since': '', 'subagents': ''})]
        processes = [(11, 10, '/bin/zsh -c source /Users/u/.claude/shell-snapshots/s.sh'),
                     (21, 20, '/bin/zsh -lc source /Users/u/.codex/shell_snapshots/s.sh'),
                     (40, 1, '/bin/zsh -c source /Users/u/.claude/shell-snapshots/s.sh'),
                     (41, 1, 'unrelated')]
        text = agent.line(panes, processes, now=125)
        self.assertIn('C main:1 Bash git 2m05 +2sa bg1', text)
        self.assertIn('X work:2 idle bg1', text)
        self.assertNotIn('idle:3', text)
        self.assertIn('orphans 1', text)

    def test_nothing_running_renders_empty(self):
        self.assertEqual(agent.line([], [], now=0), '')


if __name__ == '__main__':
    unittest.main()
