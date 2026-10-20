"""
macOS SFSpeechRecognizer bridge for Talon via the `hear` CLI.

Install hear: brew install sveinbjorn/sveinbjorn/hear

This supplements (not replaces) Talon's built-in engine.
Recognized text is pushed through Talon's grammar engine via speech_system._sim().

To disable Talon's own microphone so only this bridge runs:
  - Toggle mic off in the Talon menu and set self.enabled = True manually,
  - Or use this purely as a dictation supplement when Talon commands don't match.
"""
import shutil
import subprocess
import threading

from talon import Module, app, speech_system

mod = Module()

HEAR_BIN = shutil.which("hear")
SEGMENT_DURATION = 4  # seconds per recognition window


class MacSpeechBridge:
    def __init__(self):
        self._thread = None
        self._stop_event = threading.Event()
        self.enabled = False

    def start(self):
        if not HEAR_BIN:
            print("mac_speech: `hear` not found — install via: brew install sveinbjorn/sveinbjorn/hear")
            return
        self.enabled = True
        self._stop_event.clear()
        self._thread = threading.Thread(target=self._loop, daemon=True, name="mac_speech_bridge")
        self._thread.start()
        print("mac_speech: bridge started")

    def stop(self):
        self.enabled = False
        self._stop_event.set()
        print("mac_speech: bridge stopped")

    def _loop(self):
        while not self._stop_event.is_set():
            try:
                result = subprocess.run(
                    [HEAR_BIN, "-d", str(SEGMENT_DURATION), "-q"],
                    capture_output=True,
                    text=True,
                    timeout=SEGMENT_DURATION + 2,
                )
                text = result.stdout.strip()
                if text:
                    print(f"mac_speech: heard: {text!r}")
                    speech_system._sim(text)
            except subprocess.TimeoutExpired:
                pass
            except Exception as e:
                print(f"mac_speech: error: {e}")
                self._stop_event.wait(1)


_bridge = MacSpeechBridge()


@mod.action_class
class Actions:
    def mac_speech_start():
        """Start the macOS speech recognition bridge"""
        _bridge.start()

    def mac_speech_stop():
        """Stop the macOS speech recognition bridge"""
        _bridge.stop()
