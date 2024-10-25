import tkinter as tk
from tkinter import IntVar, ttk as ttk
from mp3tagger.data.constants import *
from mp3tagger.data.sections import *

import tkinter as tk
from tkinter import ttk as ttk
from mp3tagger.data.constants import *
from mp3tagger.data.sections import *
import logging
from typing import Any, Dict

logger = logging.getLogger(__name__)


# Only called at initialization
def build_scale(window, label, param, value, toggle_command, command):
    # print('build_scale()')
    all = tk.StringVar()

    # Set initial troughcolor
    if value == ON:
        troughcolor = 'green'
    if value == NEUTRAL:
        troughcolor = middle_color
    if value == OFF:
        troughcolor = 'coral3'

    scale = tk.Scale(window, from_=0, to=2, orient='horizontal', showvalue=0,
                     label=f"  {param}  ", length=65, sliderlength=20, width=18,
                     repeatdelay=125, troughcolor=troughcolor, variable=all, bg=bg_color, fg=fg_color, bd=3, highlightthickness=0,
                     activebackground=activebackground_color, font=param_font)
    scale.set(value)

    def update_color_and_callback(value):
        # Update the color based on the new value
        if int(float(value)) == ON:
            scale.configure(troughcolor='green')
        elif int(float(value)) == NEUTRAL:
            scale.configure(troughcolor=middle_color)
        elif int(float(value)) == OFF:
            scale.configure(troughcolor='coral3')
        
        # Call the appropriate callback
        if '*' in param:
            toggle_command(value, label)
        else:
            command(value)

    scale.configure(command=update_color_and_callback)
    
    return scale


def report_change(self, name, value):
        print("%s changed to %s" % (name, value))


# Only called at initialization
def build_section(window, section, row, column, toggle_command, command):

    # print('build_section()')

    scales = []
    
    # Toggle Control scale that will set all the scales in this section
    scale = build_scale(window, section['label'], '      *', section['group_control'], toggle_command=toggle_command, command=command)
    scale.grid(row=row, column=column, padx=10, pady=0)
    scales.append(scale)

    # The label for this section
    row = row + 1
    label = tk.Label(window, text=section['label'], bg=bg_color, fg=fg_color)
    label.config(font=(header_font, header_font_size))
    label.grid(row=row, column=column, padx=10)

    # NO BLANKS CHECKBOX
    row += 1
    variable = section['no_blanks']
    no_blanks_checkbox = tk.Checkbutton(window, variable=variable, bg=bg_color, fg=fg_color, selectcolor="#333333") # text='include blanks', 
    no_blanks_checkbox.grid(row=row, column=column)
    
    # Build each scale in this section
    for s in section['scales']:
        row = row + 1
        scale = build_scale(window, section['label'], param=s[0], value=s[1], toggle_command=toggle_command, command=command)
        scale.grid(row=row, column=column, padx=10, pady=5)
        scales.append(scale)

    section = {
        'label': label,
        'scales': scales,
        'no_blanks': variable,
    }

    return section


def clean_filter(filter):
    filter = filter.strip()
    filter = filter.strip('AND')
    filter = filter.strip('OR')
    filter = filter.strip()
    return filter


def get_filter_from_section(current_filter: str, section: Dict[str, Any], control_toggle_pressed: bool = False) -> str:
    """
    Updates the filter string based on the settings of a section.

    Args:
        current_filter (str): The current filter string (ignored in this implementation).
        section (Dict[str, Any]): The section data containing label, scales, and no_blanks.
        control_toggle_pressed (bool): Flag indicating if the section's control toggle was pressed.

    Returns:
        str: The generated filter string for this section.
    """
    label_widget = section.get("label")
    if not label_widget:
        logger.warning("Section missing 'label' widget.")
        return ""

    label_text = label_widget.cget("text")
    no_blanks = section.get("no_blanks", IntVar()).get()
    scales = section.get("scales", [])

    # Skip the control scale (first scale with '*')
    scales_to_process = [scale for scale in scales if '*' not in scale.cget("label").strip()]
    
    # Group filters by value
    on_filters = []
    off_filters = []
    
    for scale in scales_to_process:
        param = scale.cget("label").strip()
        value = scale.get()
        
        if value == ON:
            if label_text == "%_folderpath%":
                if off_filters:
                    off_filters.append(param.lower())
            else:
                on_filters.append(f"({label_text} MATCHES {param} OR {label_text} ABSENT)")
        elif value == OFF:
            if label_text == "%_folderpath%":
                if not param in off_filters:
                    off_filters.append(param.lower())
            else:
                off_filters.append(f"(NOT {label_text} MATCHES {param})")

    # Build the section filter string
    section_filters = []
    
    # Handle folderpath differently
    if label_text == "%_folderpath%" and off_filters:
        section_filters.append(f"(NOT %_folderpath% MATCHES {('|'.join(off_filters))})")
    else:
        # Add ON filters with OR between them
        if on_filters:
            section_filters.append(" OR ".join(on_filters))
        
        # Add OFF filters
        section_filters.extend(off_filters)

    # Combine section filters
    section_filter = " AND ".join(filter for filter in section_filters if filter)
    
    # Add no_blanks condition if checked
    if no_blanks:
        if section_filter:
            section_filter += " AND BLANKS ABSENT"
        else:
            section_filter = "BLANKS ABSENT"

    return section_filter