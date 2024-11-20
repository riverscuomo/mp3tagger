import sys
from subprocess import Popen
from pywinauto import Desktop
from pywinauto.application import Application
# import pywinauto
import os

def automate(filter):

    # FASTER BUT CAN'T FIND SCORE TOTAL
    try:
        # connect again with this faster way to find the filter
        app = Application().connect(path=os.environ.get("MP3TAG_PATH"))
        
    except:
        print('are you sure mp3 tag is open before you connect?')
        exit()

    window =  app.top_window()
    

    window.maximize()
    # print(dlg_spec.menu())

    # #  TAKES A LOOOOOOOOOOOONG TIME IF THERE ARE MANY SONGS IN THE VIEW
    # window.print_control_identifiers()

    # sys.exit()

    # filter.replace( '(' ,  r'\(' )
    filter = filter.replace( ')' ,  '{)}')
    filter = filter.replace( '(' ,  '{(}')
    filter = filter.replace( ' ' ,  '{ }')
    filter = filter.replace( '%' ,  '{%}')

    # filter = filter[3:5]
    print(filter)
    # https://stackoverflow.com/questions/44369703/attributeerror-windowspecification-class-has-no-typekeys-method


    # # add the filter text to the filter
    # window.child_window(best_match="ComboBox").type_keys(filter)

    # FOR NOT BACKEND = UAI
       # Clear the existing content in the ComboBox
    combo_box = window['Filte&r:ComboBox']
    combo_box.set_focus()
    combo_box.type_keys('^a')  # Ctrl+A to select all
    combo_box.type_keys('{BACKSPACE}')  # Clear the selected text
    window['Filte&r:ComboBox'].send_chars(filter)


if __name__ == '__main__':
    filter_arg = sys.argv[1] if len(sys.argv) > 1 else ''
    automate(filter_arg)
