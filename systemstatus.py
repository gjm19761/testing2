import tkinter as tk
from tkinter import ttk
import psutil
import platform

class SystemMonitorGUI:
    def __init__(self, master):
        self.master = master
        master.title("System Monitor")
        master.geometry("400x300")

        self.notebook = ttk.Notebook(master)
        self.notebook.pack(expand=True, fill="both", padx=10, pady=10)

        self.create_cpu_tab()
        self.create_memory_tab()
        self.create_disk_tab()
        self.create_network_tab()

        self.update()

    def create_cpu_tab(self):
        cpu_frame = ttk.Frame(self.notebook)
        self.notebook.add(cpu_frame, text="CPU")

        self.cpu_usage = ttk.Label(cpu_frame, text="CPU Usage: ")
        self.cpu_usage.pack(pady=10)

        self.cpu_freq = ttk.Label(cpu_frame, text="CPU Frequency: ")
        self.cpu_freq.pack(pady=10)

    def create_memory_tab(self):
        memory_frame = ttk.Frame(self.notebook)
        self.notebook.add(memory_frame, text="Memory")

        self.memory_usage = ttk.Label(memory_frame, text="Memory Usage: ")
        self.memory_usage.pack(pady=10)

    def create_disk_tab(self):
        disk_frame = ttk.Frame(self.notebook)
        self.notebook.add(disk_frame, text="Disk")

        self.disk_usage = ttk.Label(disk_frame, text="Disk Usage: ")
        self.disk_usage.pack(pady=10)

    def create_network_tab(self):
        network_frame = ttk.Frame(self.notebook)
        self.notebook.add(network_frame, text="Network")

        self.network_io = ttk.Label(network_frame, text="Network I/O: ")
        self.network_io.pack(pady=10)

    def update(self):
        # Update CPU info
        cpu_percent = psutil.cpu_percent()
        cpu_freq = psutil.cpu_freq().current
        self.cpu_usage.config(text=f"CPU Usage: {cpu_percent}%")
        self.cpu_freq.config(text=f"CPU Frequency: {cpu_freq:.2f} MHz")

        # Update Memory info
        memory = psutil.virtual_memory()
        self.memory_usage.config(text=f"Memory Usage: {memory.percent}%")

        # Update Disk info
        disk = psutil.disk_usage('/')
        self.disk_usage.config(text=f"Disk Usage: {disk.percent}%")

        # Update Network info
        net_io = psutil.net_io_counters()
        self.network_io.config(text=f"Network I/O: {net_io.bytes_sent / (1024*1024):.2f} MB sent, {net_io.bytes_recv / (1024*1024):.2f} MB received")

        self.master.after(1000, self.update)  # Update every 1 second

if __name__ == "__main__":
    root = tk.Tk()
    app = SystemMonitorGUI(root)
    root.mainloop()
