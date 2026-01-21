# pywadadvance_gui.py
import sys
import os
import traceback
import subprocess
from pathlib import Path
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QLabel, QLineEdit, QPushButton, 
                             QTextEdit, QProgressBar, QCheckBox, QGroupBox,
                             QFileDialog, QMessageBox, QTabWidget, QListWidget,
                             QListWidgetItem, QSplitter, QFrame, QScrollArea)
from PyQt5.QtCore import Qt, QThread, pyqtSignal
from PyQt5.QtGui import QFont, QPalette, QColor

# Import the core functionality
try:
    from pywadadvance_core import main as core_main, WAD, parse_dehacked_structured
    CORE_AVAILABLE = True
except ImportError as e:
    print(f"Core module import failed: {e}")
    CORE_AVAILABLE = False

class ConversionThread(QThread):
    """Thread for running the WAD conversion to prevent GUI freezing"""
    progress_signal = pyqtSignal(str)
    finished_signal = pyqtSignal(bool, str)
    
    def __init__(self, src_path, out_path, deh_files, options):
        super().__init__()
        self.src_path = src_path
        self.out_path = out_path
        self.deh_files = deh_files
        self.options = options
    
    def run(self):
        try:
            # Prepare DEH files data
            deh_data = []
            for deh_file in self.deh_files:
                try:
                    with open(deh_file, 'rb') as f:
                        deh_data.append((os.path.basename(deh_file), f.read()))
                    self.progress_signal.emit(f"Loaded DEH file: {os.path.basename(deh_file)}")
                except Exception as e:
                    self.progress_signal.emit(f"Error loading {deh_file}: {e}")
            
            # Call the core main function
            self.progress_signal.emit("Starting conversion...")
            core_main(self.src_path, self.out_path, deh_data, self.options)
            self.progress_signal.emit("Conversion completed successfully!")
            self.finished_signal.emit(True, "Conversion completed successfully!")
            
        except Exception as e:
            error_msg = f"Conversion failed: {str(e)}\n\nTraceback:\n{traceback.format_exc()}"
            self.progress_signal.emit(error_msg)
            self.finished_signal.emit(False, error_msg)

class WadAdvanceGUI(QMainWindow):
    def __init__(self):
        super().__init__()
        self.src_file = ""
        self.deh_files = []
        self.launch_files = []  # Files for the launch group
        self.init_ui()
        
    def init_ui(self):
        self.setWindowTitle("WAD Advance - SRB2 DOOM Port Preparer")
        self.setGeometry(100, 100, 900, 700)
        
        # Central widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        # Main layout
        layout = QVBoxLayout(central_widget)
        
        # Create tabs
        tabs = QTabWidget()
        layout.addWidget(tabs)
        
        # Main conversion tab
        main_tab = QWidget()
        tabs.addTab(main_tab, "Main Conversion")
        
        # SRB2 Launcher tab
        launcher_tab = QWidget()
        tabs.addTab(launcher_tab, "SRB2 Launcher")
        
        # Options tab
        options_tab = QWidget()
        tabs.addTab(options_tab, "Options")
        
        # Setup tabs
        self.setup_main_tab(main_tab)
        self.setup_launcher_tab(launcher_tab)
        self.setup_options_tab(options_tab)
        
        # Status bar (using a simple label instead of QStatusBar)
        self.status_label = QLabel("Ready")
        layout.addWidget(self.status_label)
    
    def setup_main_tab(self, tab):
        layout = QVBoxLayout(tab)
        
        # Source file selection
        src_group = QGroupBox("Source WAD/PK3")
        src_layout = QVBoxLayout(src_group)
        
        src_file_layout = QHBoxLayout()
        self.src_file_label = QLabel("No file selected")
        self.src_file_label.setWordWrap(True)
        src_file_layout.addWidget(self.src_file_label)
        
        self.src_browse_btn = QPushButton("Browse...")
        self.src_browse_btn.clicked.connect(self.browse_src_file)
        src_file_layout.addWidget(self.src_browse_btn)
        
        src_layout.addLayout(src_file_layout)
        layout.addWidget(src_group)
        
        # DEH/BEX files
        deh_group = QGroupBox("DEHACKED/BEX Files (Optional)")
        deh_layout = QVBoxLayout(deh_group)
        
        self.deh_list = QListWidget()
        deh_layout.addWidget(self.deh_list)
        
        deh_buttons_layout = QHBoxLayout()
        self.add_deh_btn = QPushButton("Add DEH/BEX...")
        self.add_deh_btn.clicked.connect(self.add_deh_file)
        self.remove_deh_btn = QPushButton("Remove Selected")
        self.remove_deh_btn.clicked.connect(self.remove_deh_file)
        
        deh_buttons_layout.addWidget(self.add_deh_btn)
        deh_buttons_layout.addWidget(self.remove_deh_btn)
        deh_buttons_layout.addStretch()
        
        deh_layout.addLayout(deh_buttons_layout)
        layout.addWidget(deh_group)
        
        # Output file
        out_group = QGroupBox("Output")
        out_layout = QVBoxLayout(out_group)
        
        out_file_layout = QHBoxLayout()
        self.out_file_edit = QLineEdit()
        self.out_file_edit.setPlaceholderText("Output file path...")
        out_file_layout.addWidget(self.out_file_edit)
        
        self.out_browse_btn = QPushButton("Browse...")
        self.out_browse_btn.clicked.connect(self.browse_out_file)
        out_file_layout.addWidget(self.out_browse_btn)
        
        out_layout.addLayout(out_file_layout)
        layout.addWidget(out_group)
        
        # Progress area
        progress_group = QGroupBox("Conversion Progress")
        progress_layout = QVBoxLayout(progress_group)
        
        self.progress_text = QTextEdit()
        self.progress_text.setReadOnly(True)
        self.progress_text.setMaximumHeight(200)
        progress_layout.addWidget(self.progress_text)
        
        self.progress_bar = QProgressBar()
        self.progress_bar.setVisible(False)
        progress_layout.addWidget(self.progress_bar)
        
        layout.addWidget(progress_group)
        
        # Convert button
        self.convert_btn = QPushButton("Convert WAD")
        self.convert_btn.clicked.connect(self.start_conversion)
        self.convert_btn.setStyleSheet("QPushButton { background-color: #4CAF50; color: white; font-weight: bold; padding: 10px; }")
        layout.addWidget(self.convert_btn)
    
    def setup_launcher_tab(self, tab):
        layout = QVBoxLayout(tab)
        
        # SRB2 Executable
        exe_group = QGroupBox("SRB2 Executable")
        exe_layout = QVBoxLayout(exe_group)
        
        exe_file_layout = QHBoxLayout()
        self.exe_file_edit = QLineEdit()
        self.exe_file_edit.setPlaceholderText("Path to srb2win.exe, srb2.exe, or other SRB2 executable...")
        exe_file_layout.addWidget(self.exe_file_edit)
        
        self.exe_browse_btn = QPushButton("Browse...")
        self.exe_browse_btn.clicked.connect(self.browse_exe_file)
        exe_file_layout.addWidget(self.exe_browse_btn)
        
        exe_layout.addLayout(exe_file_layout)
        layout.addWidget(exe_group)
        
        # Engine file
        engine_group = QGroupBox("Engine (SL_DOOM-v1.pk3)")
        engine_layout = QVBoxLayout(engine_group)
        
        engine_file_layout = QHBoxLayout()
        self.engine_file_edit = QLineEdit()
        self.engine_file_edit.setPlaceholderText("Path to SL_DOOM-v1.pk3 or similar engine file...")
        engine_file_layout.addWidget(self.engine_file_edit)
        
        self.engine_browse_btn = QPushButton("Browse...")
        self.engine_browse_btn.clicked.connect(self.browse_engine_file)
        engine_file_layout.addWidget(self.engine_browse_btn)
        
        engine_layout.addLayout(engine_file_layout)
        layout.addWidget(engine_group)
        
        # IWAD file
        iwad_group = QGroupBox("IWAD (e.g., DOOM.WAD)")
        iwad_layout = QVBoxLayout(iwad_group)
        
        iwad_file_layout = QHBoxLayout()
        self.iwad_file_edit = QLineEdit()
        self.iwad_file_edit.setPlaceholderText("Path to DOOM.WAD, DOOM2.WAD, or other IWAD...")
        iwad_file_layout.addWidget(self.iwad_file_edit)
        
        self.iwad_browse_btn = QPushButton("Browse...")
        self.iwad_browse_btn.clicked.connect(self.browse_iwad_file)
        iwad_file_layout.addWidget(self.iwad_browse_btn)
        
        iwad_layout.addLayout(iwad_file_layout)
        layout.addWidget(iwad_group)
        
        # Additional files group
        files_group = QGroupBox("Additional Files")
        files_layout = QVBoxLayout(files_group)
        
        self.files_list = QListWidget()
        files_layout.addWidget(self.files_list)
        
        files_buttons_layout = QHBoxLayout()
        self.add_file_btn = QPushButton("Add File...")
        self.add_file_btn.clicked.connect(self.add_launch_file)
        self.remove_file_btn = QPushButton("Remove Selected")
        self.remove_file_btn.clicked.connect(self.remove_launch_file)
        self.move_up_btn = QPushButton("Move Up")
        self.move_up_btn.clicked.connect(self.move_file_up)
        self.move_down_btn = QPushButton("Move Down")
        self.move_down_btn.clicked.connect(self.move_file_down)
        
        files_buttons_layout.addWidget(self.add_file_btn)
        files_buttons_layout.addWidget(self.remove_file_btn)
        files_buttons_layout.addWidget(self.move_up_btn)
        files_buttons_layout.addWidget(self.move_down_btn)
        files_buttons_layout.addStretch()
        
        files_layout.addLayout(files_buttons_layout)
        layout.addWidget(files_group)
        
        # Command preview
        command_group = QGroupBox("Command Preview")
        command_layout = QVBoxLayout(command_group)
        
        self.command_preview = QTextEdit()
        self.command_preview.setReadOnly(True)
        self.command_preview.setMaximumHeight(80)
        self.command_preview.setPlaceholderText("The generated command will appear here...")
        command_layout.addWidget(self.command_preview)
        
        layout.addWidget(command_group)
        
        # Launch button
        self.launch_btn = QPushButton("Launch SRB2")
        self.launch_btn.clicked.connect(self.launch_srb2)
        self.launch_btn.setStyleSheet("QPushButton { background-color: #2196F3; color: white; font-weight: bold; padding: 10px; }")
        layout.addWidget(self.launch_btn)
        
        # Connect signals to update command preview
        self.exe_file_edit.textChanged.connect(self.update_command_preview)
        self.engine_file_edit.textChanged.connect(self.update_command_preview)
        self.iwad_file_edit.textChanged.connect(self.update_command_preview)
        self.files_list.model().rowsMoved.connect(self.update_command_preview)
    
    def setup_options_tab(self, tab):
        layout = QVBoxLayout(tab)
        
        # Optional features
        optional_group = QGroupBox("Optional Features")
        optional_layout = QVBoxLayout(optional_group)
        
        self.midi_to_ogg_cb = QCheckBox("Convert MIDI to OGG (requires FluidSynth & FFmpeg)")
        self.midi_to_ogg_cb.setChecked(False)
        optional_layout.addWidget(self.midi_to_ogg_cb)
        
        # DMXGUS options
        dmxgus_group = QGroupBox("DMXGUS MIDI Remapping")
        dmxgus_layout = QVBoxLayout(dmxgus_group)
        
        self.use_dmxgus_cb = QCheckBox("Apply DMXGUS instrument remapping to MIDI")
        self.use_dmxgus_cb.setChecked(False)
        dmxgus_layout.addWidget(self.use_dmxgus_cb)
        """
        # Memory size selection
        memory_layout = QHBoxLayout()
        memory_label = QLabel("Memory size:")
        self.memory_combo = QComboBox()
        self.memory_combo.addItems(["256 KB", "512 KB", "768 KB", "1024 KB"])
        self.memory_combo.setCurrentIndex(1)  # Default to 512KB
        memory_layout.addWidget(memory_label)
        memory_layout.addWidget(self.memory_combo)
        memory_layout.addStretch()
        dmxgus_layout.addLayout(memory_layout)
        """
        # Fallback WAD
        fallback_layout = QHBoxLayout()
        fallback_label = QLabel("Fallback WAD:")
        self.fallback_edit = QLineEdit()
        self.fallback_edit.setPlaceholderText("Optional: WAD containing DMXGUS lump")
        self.fallback_browse_btn = QPushButton("Browse...")
        self.fallback_browse_btn.clicked.connect(self.browse_fallback_wad)
        fallback_layout.addWidget(fallback_label)
        fallback_layout.addWidget(self.fallback_edit)
        fallback_layout.addWidget(self.fallback_browse_btn)
        dmxgus_layout.addLayout(fallback_layout)
        
        #optional_layout.addWidget(dmxgus_group)
        
        self.normalize_pegging_cb = QCheckBox("Normalize pegging flags (DOOM-style midtextures)")
        self.normalize_pegging_cb.setChecked(True)
        optional_layout.addWidget(self.normalize_pegging_cb)
        
        self.player_sprites_cb = QCheckBox("Create player sprites from PLAY lumps")
        self.player_sprites_cb.setChecked(True)
        optional_layout.addWidget(self.player_sprites_cb)
        
        self.use_pcspeaker_cb = QCheckBox("Replace sounds with PC Speaker variants")
        self.use_pcspeaker_cb.setChecked(False)
        optional_layout.addWidget(self.use_pcspeaker_cb)
        
        layout.addWidget(optional_group)
        
        # PK3 Options
        pk3_group = QGroupBox("PK3 Options")
        pk3_layout = QVBoxLayout(pk3_group)
        
        self.auto_pk3_cb = QCheckBox("Auto-detect and process nested WADs in PK3")
        self.auto_pk3_cb.setChecked(True)
        pk3_layout.addWidget(self.auto_pk3_cb)
        
        self.stcfn_uppercase_to_lowercase_cb = QCheckBox("Copy STCFN uppercase graphics to lowercase letter codes")
        self.stcfn_uppercase_to_lowercase_cb.setChecked(True)
        pk3_layout.addWidget(self.stcfn_uppercase_to_lowercase_cb)
        
        self.suppress_pskin_errors_cb = QCheckBox("Suppress errors in player sprite creation")
        self.suppress_pskin_errors_cb.setChecked(False)
        pk3_layout.addWidget(self.suppress_pskin_errors_cb)
        
        layout.addWidget(pk3_group)
        
        layout.addStretch()
        
        # Reset to defaults button
        self.reset_btn = QPushButton("Reset to Defaults")
        self.reset_btn.clicked.connect(self.reset_options)
        layout.addWidget(self.reset_btn)
    
    def browse_src_file(self):
        file_path, _ = QFileDialog.getOpenFileName(
            self, 
            "Select Source WAD or PK3", 
            "", 
            "WAD/PK3 Files (*.wad *.WAD *.pk3 *.PK3);;All Files (*)"
        )
        if file_path:
            self.src_file = file_path
            self.src_file_label.setText(file_path)
            
            # Auto-generate output filename
            if not self.out_file_edit.text():
                base_name = Path(file_path).stem
                output_path = str(Path(file_path).parent / f"{base_name}.pk3")
                self.out_file_edit.setText(output_path)
    
    def browse_out_file(self):
        file_path, _ = QFileDialog.getSaveFileName(
            self,
            "Select Output WAD or PK3",
            self.out_file_edit.text() or "",
            "WAD/PK3 Files (*.wad *.WAD *.pk3 *.PK3);;All Files (*)"
        )
        if file_path:
            self.out_file_edit.setText(file_path)
    
    def browse_exe_file(self):
        file_path, _ = QFileDialog.getOpenFileName(
            self,
            "Select SRB2 Executable",
            "",
            "Executable Files (*.exe);;All Files (*)"
        )
        if file_path:
            self.exe_file_edit.setText(file_path)
            self.update_command_preview()
    
    def browse_engine_file(self):
        file_path, _ = QFileDialog.getOpenFileName(
            self,
            "Select Engine File (SL_DOOM-v1.pk3)",
            "",
            "PK3 Files (*.pk3 *.PK3);;All Files (*)"
        )
        if file_path:
            self.engine_file_edit.setText(file_path)
            self.update_command_preview()
    
    def browse_iwad_file(self):
        file_path, _ = QFileDialog.getOpenFileName(
            self,
            "Select IWAD File",
            "",
            "WAD/PK3 Files (*.wad *.WAD *.pk3 *.PK3);;All Files (*)"
        )
        if file_path:
            self.iwad_file_edit.setText(file_path)
            self.update_command_preview()
    
    def add_deh_file(self):
        file_paths, _ = QFileDialog.getOpenFileNames(
            self,
            "Select DEHACKED/BEX Files",
            "",
            "DEHACKED Files (*.deh *.DEH *.bex *.BEX);;All Files (*)"
        )
        for file_path in file_paths:
            if file_path not in self.deh_files:
                self.deh_files.append(file_path)
                item = QListWidgetItem(os.path.basename(file_path))
                item.setToolTip(file_path)
                self.deh_list.addItem(item)
    
    def remove_deh_file(self):
        current_row = self.deh_list.currentRow()
        if current_row >= 0:
            self.deh_files.pop(current_row)
            self.deh_list.takeItem(current_row)
    
    def add_launch_file(self):
        file_paths, _ = QFileDialog.getOpenFileNames(
            self,
            "Select Additional Files for Launch",
            "",
            "All Supported Files (*.pk3 *.PK3 *.wad *.WAD *.deh *.DEH *.bex *.BEX);;All Files (*)"
        )
        for file_path in file_paths:
            if file_path not in self.launch_files:
                self.launch_files.append(file_path)
                item = QListWidgetItem(os.path.basename(file_path))
                item.setToolTip(file_path)
                self.files_list.addItem(item)
                self.update_command_preview()
    
    def remove_launch_file(self):
        current_row = self.files_list.currentRow()
        if current_row >= 0:
            self.launch_files.pop(current_row)
            self.files_list.takeItem(current_row)
            self.update_command_preview()
    
    def move_file_up(self):
        current_row = self.files_list.currentRow()
        if current_row > 0:
            # Move in our internal list
            self.launch_files[current_row], self.launch_files[current_row - 1] = \
                self.launch_files[current_row - 1], self.launch_files[current_row]
            
            # Move in the list widget
            item = self.files_list.takeItem(current_row)
            self.files_list.insertItem(current_row - 1, item)
            self.files_list.setCurrentRow(current_row - 1)
            self.update_command_preview()
    
    def move_file_down(self):
        current_row = self.files_list.currentRow()
        if current_row < self.files_list.count() - 1 and current_row >= 0:
            # Move in our internal list
            self.launch_files[current_row], self.launch_files[current_row + 1] = \
                self.launch_files[current_row + 1], self.launch_files[current_row]
            
            # Move in the list widget
            item = self.files_list.takeItem(current_row)
            self.files_list.insertItem(current_row + 1, item)
            self.files_list.setCurrentRow(current_row + 1)
            self.update_command_preview()
    
    def update_command_preview(self):
        exe_path = self.exe_file_edit.text().strip()
        engine_path = self.engine_file_edit.text().strip()
        iwad_path = self.iwad_file_edit.text().strip()
        
        if not exe_path:
            self.command_preview.setText("")
            return
        
        # Build the command
        command_parts = [f'"{exe_path}"']
        
        # Collect all files that should go after -file flag
        files_to_load = []
        
        if engine_path:
            files_to_load.append(engine_path)
        
        if iwad_path:
            files_to_load.append(iwad_path)
        
        # Add additional files in order
        files_to_load.extend(self.launch_files)
        
        # Add all files with single -file flag
        if files_to_load:
            file_args = ' '.join(f'"{f}"' for f in files_to_load)
            command_parts.append(f'-file {file_args}')

        # Append "+skin johndoom" since that's the intended experience
        # (Would just be overriden by user if they go into multiplayer/SRB2 Menu/console/whatever thefuck anyway)
        command_parts.append("+skin johndoom")
        
        command = " ".join(command_parts)
        self.command_preview.setText(command)
    
    def launch_srb2(self):
        exe_path = self.exe_file_edit.text().strip()
        
        if not exe_path:
            QMessageBox.warning(self, "Warning", "Please select an SRB2 executable.")
            return
        
        if not os.path.exists(exe_path):
            QMessageBox.warning(self, "Warning", f"SRB2 executable not found:\n{exe_path}")
            return
        
        try:
            # Get the command from the preview
            command = self.command_preview.toPlainText().strip()
            
            if not command:
                QMessageBox.warning(self, "Warning", "No command to execute.")
                return
            
            # Launch SRB2
            self.status_label.setText("Launching SRB2...")
            
            # Set working directory to the directory containing the executable
            exe_dir = os.path.dirname(os.path.abspath(exe_path))
            
            # Use subprocess to launch the game with proper working directory
            subprocess.Popen(command, shell=True, cwd=exe_dir)
            
            self.status_label.setText("SRB2 launched successfully")
            
        except Exception as e:
            error_msg = f"Failed to launch SRB2: {str(e)}"
            QMessageBox.critical(self, "Error", error_msg)
            self.status_label.setText("Failed to launch SRB2")
  
    def browse_fallback_wad(self):
        file_path, _ = QFileDialog.getOpenFileName(
            self,
            "Select Fallback WAD with DMXGUS",
            "",
            "WAD Files (*.wad *.WAD);;All Files (*)"
        )
        if file_path:
            self.fallback_edit.setText(file_path)
  
    def get_options(self):
        #memory_text = self.memory_combo.currentText()
        #memory_kb = int(memory_text.split()[0])
        
        # TODO: How does the DMXGUS drum patch remappings work?
        return {
            'midi_to_ogg': self.midi_to_ogg_cb.isChecked(),
            #'use_dmxgus': self.use_dmxgus_cb.isChecked(),
            #'dmxgus_memory': memory_kb,
            #'dmxgus_fallback': self.fallback_edit.text() or None,
            'normalize_pegging': self.normalize_pegging_cb.isChecked(),
            'player_sprites': self.player_sprites_cb.isChecked(),
            'use_pcspeaker': self.use_pcspeaker_cb.isChecked(),
            'auto_pk3': self.auto_pk3_cb.isChecked(),
            'stcfn_uppercase_to_lowercase': self.stcfn_uppercase_to_lowercase_cb.isChecked(),
            'suppress_pskin_errors': self.suppress_pskin_errors_cb.isChecked()
        }
    
    def reset_options(self):
        self.midi_to_ogg_cb.setChecked(False)
        self.use_dmxgus_cb.setChecked(False)
        self.memory_combo.setCurrentIndex(1)  # 512KB
        self.fallback_edit.clear()
        self.normalize_pegging_cb.setChecked(True)
        self.player_sprites_cb.setChecked(True)
        self.use_pcspeaker_cb.setChecked(False)
        self.auto_pk3_cb.setChecked(True)
        self.stcfn_uppercase_to_lowercase_cb.setChecked(True)
        self.suppress_pskin_errors_cb.setChecked(False)

    def start_conversion(self):
        if not CORE_AVAILABLE:
            QMessageBox.critical(self, "Error", "Core conversion module not available. Please ensure pywadadvance_core.py is in the same directory.")
            return
        
        if not self.src_file:
            QMessageBox.warning(self, "Warning", "Please select a source WAD/PK3 file.")
            return
        
        if not self.out_file_edit.text():
            QMessageBox.warning(self, "Warning", "Please specify an output file path.")
            return
        
        # Disable UI during conversion
        self.set_ui_enabled(False)
        self.progress_bar.setVisible(True)
        self.progress_text.clear()
        
        # Start conversion thread
        self.conversion_thread = ConversionThread(
            self.src_file,
            self.out_file_edit.text(),
            self.deh_files,
            self.get_options()
        )
        self.conversion_thread.progress_signal.connect(self.update_progress)
        self.conversion_thread.finished_signal.connect(self.conversion_finished)
        self.conversion_thread.start()
    
    def set_ui_enabled(self, enabled):
        self.src_browse_btn.setEnabled(enabled)
        self.add_deh_btn.setEnabled(enabled)
        self.remove_deh_btn.setEnabled(enabled)
        self.out_browse_btn.setEnabled(enabled)
        self.convert_btn.setEnabled(enabled)
        self.convert_btn.setText("Converting..." if not enabled else "Convert WAD")
    
    def update_progress(self, message):
        self.progress_text.append(message)
        self.status_label.setText(message)
        
        # Auto-scroll to bottom
        scrollbar = self.progress_text.verticalScrollBar()
        scrollbar.setValue(scrollbar.maximum())
    
    def conversion_finished(self, success, message):
        self.set_ui_enabled(True)
        self.progress_bar.setVisible(False)
        
        if success:
            QMessageBox.information(self, "Success", "Conversion completed successfully!")
            self.status_label.setText("Conversion completed")
        else:
            QMessageBox.critical(self, "Error", f"Conversion failed:\n{message}")
            self.status_label.setText("Conversion failed")

def main():
    app = QApplication(sys.argv)
    
    # Set application style
    app.setStyle('Fusion')
    
    # Check if core is available
    if not CORE_AVAILABLE:
        msg = QMessageBox()
        msg.setIcon(QMessageBox.Critical)
        msg.setWindowTitle("Error")
        msg.setText("Core module not found")
        msg.setInformativeText(
            "Please ensure pywadadvance_core.py is in the same directory.\n\n"
            "The core functionality is required for WAD conversion."
        )
        msg.exec_()
        return 1
    
    window = WadAdvanceGUI()
    window.show()
    
    return app.exec_()

if __name__ == '__main__':
    sys.exit(main())