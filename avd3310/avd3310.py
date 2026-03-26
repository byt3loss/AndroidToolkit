import subprocess
import threading
from rich.console import Console
import questionary
import sys

class EmulatorManager:
    def __init__(self):
        self.process = None
        self.avds = self.get_avds()
        self.running_avd = None
        self.logs = []

    def start(self, avd_name):
        if self.process and self.process.poll() is None:
            print("An AVD is already running")
            return

        cmd = [
            "emulator",
            "-avd",
            avd_name,
            "-no-snapshot",
            "-writable-system"
        ]

        self.process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )
        
        threading.Thread(target=self._read_logs, daemon=True).start()

        print(f"Emulator started (PID {self.process.pid})")

        self.running_avd = avd_name

    def stop(self):
        if not self.process:
            print("No AVD running")
            return

        print("Stopping AVD via adb...")

        try:
            subprocess.run(["adb", "emu", "kill"])
        except Exception:
            print("Fallback to SIGKILL")
            self.process.kill()

        self.process = None
        self.running_avd = None

    def status(self):
        if self.process and self.process.poll() is None:
            print(f"[{self.running_avd}] Status: Running ✅")
        else:
            print("Status: Stopped ❌")

    def _read_logs(self):
        for line in self.process.stdout:
            self.logs.append(line)

    def show_logs(self):
        console.print("".join(self.logs[-50:]), style="green")

    def get_avds(self):
        cmd = subprocess.run(["emulator", "-list-avds"], stdout=subprocess.PIPE)
        if cmd.returncode == 0:
            return cmd.stdout.decode().splitlines()
        return []

if __name__ == "__main__":
    mgr = EmulatorManager()
    console = Console()

    main_menu = [
        questionary.Choice(title="🚀 Start AVD", value="start"),
        questionary.Choice(title="💥 Stop AVD", value="stop"),
        questionary.Choice(title="🩺 Status", value="status"),
        questionary.Choice(title="👽 Logs", value="logs"),
        questionary.Choice(title="💔 Exit", value="exit"),
    ]
    
    while True:
        action = questionary.select(
            "👾 AVD-3310",
            choices = main_menu
        ).ask()

        if action == "start":
            if len(mgr.avds) > 0:
                choices = mgr.avds + ["↩️  Back"]
                choice = questionary.select(
                    "Choose an AVD to start:",
                    choices=choices
                ).ask()
                if choice == choices[-1]:
                    continue
                else:
                    mgr.start(choice)
        elif action == "stop":
            mgr.stop()
        elif action == "status":
            mgr.status()
        elif action == "logs":
            mgr.show_logs()
        else:
            if mgr.process:
                mgr.stop()
            print("Bye bye!")
            sys.exit(1)


        